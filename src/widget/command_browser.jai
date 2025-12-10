open_command_browser :: () {
    using command_browser;

    reset_widget_allocator(*widget_allocator);

    if self_text_input {
        clear_text(self_text_input);
    } else {
        self_text_input = create_text_input(COMMAND_BROWSER_UI_ID);        
    }

    array_reset_keeping_memory(*options);
    for * cmd: editor_commands {
        opt := array_add(*options);
        opt.label_styled.default_colorv4 = map_color_to_vec4(.TEXT_DEFAULT);
        
        name := cmd.name;
        if cmd.custom_command then name = tprint("[Command] %", cmd.name);
        
        opt.label = copy_string(name,, allocator=wallocator);
        opt.label_for_search = copy_string(trim(name),, allocator=wallocator);
        opt.ref = cmd;
    }

    switch_editor_mode(.WIDGET);
    active_widget = Command_Browser;
}

COMMAND_BROWSER_UI_ID :: cast(Ui_Id) #location();

command_browser: Command_Browser;

Command_Browser :: struct {
    search_text: string;

    self_text_input: *Text_Input;

    options: [..] List_Input.Option(*Editor_Command);
    
    widget_allocator: Widget_Allocator;
    #overlay(widget_allocator.allocator) wallocator: Allocator;
}