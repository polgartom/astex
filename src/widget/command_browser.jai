open_command_browser :: () {
    using command_browser;

    if self_text_input {
        clear_text(self_text_input);
    } else {
        self_text_input = create_text_input(COMMAND_BROWSER_UI_ID);        
    }

    array_reset_keeping_memory(*options);
    for * cmd: editor_commands {
        opt := array_add(*options);
        
        name := cmd.name;
        if cmd.custom_command then name = tprint("[Command] %", cmd.name);
        
        modify_string(*opt.label, name);
        modify_string(*opt.label_for_search, replace(name, " ", "",, temp));
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
}