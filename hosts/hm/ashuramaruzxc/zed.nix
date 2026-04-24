_: {
  programs.zed-editor.userSettings = {
    autosave = {
      after_delay.milliseconds = 1000;
    };
    buffer_font_family = "MesloLGL Nerd Font";
    buffer_font_size = 19;
    disable_ai = true;
    ensure_final_newline_on_save = true;
    format_on_save = "on";
    preferred_line_length = 120;
    project_panel = {
      dock = "right";
    };
    remove_trailing_whitespace_on_save = true;
    show_whitespaces = "selection";
    soft_wrap = "editor_width";
    tab_size = 2;
    terminal = {
      blinking = "terminal_controlled";
      font_family = "Hack Nerd Font";
    };
    ui_font_family = "MesloLGL Nerd Font";
    ui_font_size = 19;
    context = {
      Workspace = {
        bindings = {
          "ctrl-b" = "workspace::ToggleRightDock";
        };
      };
    };
  };
}
