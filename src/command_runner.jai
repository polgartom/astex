init_command_runner :: () {
    thread_group = Thread_Group.{};  // in case we need to reinitialise it later
    
    init(*output_lock);
    
    init(*thread_group, num_threads = 1, group_proc = command_threadproc);
    start(*thread_group);
}

deinit_command_runner :: () {
    shutdown(*thread_group);
}

execute_custom_command :: (using cmd: Editor_Command) {
    assert(buffer.kind == .stdout && buffer.readonly);
    
    buffer.stdout_in_progress = true;
    buffer.stdout_stalled = true;
    
    work := New(Custom_Command_Work);
    work.buffer = buffer;
    
    assert(!!workdir && !!exec);
    work.command = copy_string(exec);
    work.workdir = copy_string(workdir);
        
    add_work(*thread_group, work);
}

command_runner_update :: () {
    if current_work {
        lock(*output_lock);
        
        output := builder_to_string(*stdout, do_reset=true);
        output_err := builder_to_string(*stderr, do_reset=true);
        
        buffer := current_work.buffer;
        
        if current_work.done {
            current_work = null;
        }
                       
        insert_text_at_raw(buffer, buffer.count, output);
        insert_text_at_raw(buffer, buffer.count, output_err);
        rescan_line_ends(buffer);
                
        if output.count + output_err.count > 0 {
            editor := get_bottom_editor();
            set_cursor_pos(buffer, *buffer.cursor_backup[2], buffer.count, horizontal=true);
            if editor.active_buffer == buffer {
                editor.cursor = buffer.cursor_backup[2];
            }
        }
        
        free_string(*output);
        free_string(*output_err);
        
        unlock(*output_lock);
    }
    
    works := get_completed_work(*thread_group);
    if works {
        for works {
            work := cast(*Custom_Command_Work) it;
            // push_user_notification(tprint("% work is done!", work.command), .SUCCESS, 2.0);
            
            free_string(*work.command);
            free_string(*work.workdir);
            defer free(work);
            log("work: %\n", work.*);
        }
    }
}

#scope_file

Custom_Command_Work :: struct {
    buffer: *Buffer;
    workdir: string;
    done: bool;
    command: string;
}

stdout: String_Builder;
stderr: String_Builder;
output_lock: Mutex;

current_work: *Custom_Command_Work;

command_threadproc :: (group: *Thread_Group, thread: *Thread, _work: *void) -> Thread_Continue_Status {
    assert(_work != null);
    
    defer reset_temporary_storage();
    
    work := cast(*Custom_Command_Work)_work;
    assert(!!work.command);
    
    lock(*output_lock);
    current_work = work;
    work.buffer.stdout_stalled = false;
    unlock(*output_lock);
     
    command: [..] string;
    command.allocator = temporary_allocator;
    
    array_add(*command, work.command);

//     
    // // @Temporary
    // #if DEBUG {
        // array_add(*command, "../dwrite_jai/main.exe");
    // } else {
        // array_add(*command, "jai first.jai - autorun");
    // }
    
    KILL_PROCESS_IF_THE_MAIN_PROCESS_DIES :: true;
    process := New(Process);
    success := create_process(process, args=..command, work.workdir, capture_and_return_output=true, .NEVER_QUOTE, kill_process_if_parent_exits = KILL_PROCESS_IF_THE_MAIN_PROCESS_DIES);
    
    eof := false;
    while !eof {
        lock(*output_lock);
        
        stdout_buf := ensure_contiguous_space_and_return_available_range(*stdout);
        stderr_buf := ensure_contiguous_space_and_return_available_range(*stderr);
        
        INFINITE :: -1;
        timeout_ms := 5;
        success, output_bytes, error_bytes := read_from_process(process, stdout_buf, stderr_buf, timeout_ms);
        eof = (process.output.eof && process.error.eof) || !success;
        
        if output_bytes {
            advance_through_ensured_space(*stdout, output_bytes);
        }
        
        if error_bytes {
            advance_through_ensured_space(*stderr, error_bytes);
        }
    
        // ll("success: % ; out: % ; err: % ; eof: %\n", success, output_bytes, error_bytes, eof);
        
        unlock(*output_lock);
        wake_up_main_thread();
        sleep_milliseconds(10);
    }
    
    {
        success := kill_process(process);
        deinit(process);
        free(process);
    }
    
    log("stop..\n");
    
    lock(*output_lock);
    work.buffer.stdout_in_progress = false;
    work.done = true;
    unlock(*output_lock);
    
    return .CONTINUE;
}

thread_group: Thread_Group;