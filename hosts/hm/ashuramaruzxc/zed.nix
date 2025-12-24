_: {
  programs.zed-editor.userSettings = {
    disable_ai = true;
    ensure_final_newline_on_save = true;
    project_panel = "right";
    remove_trailing_whitespace_on_save = true;
    context = {
      Workspace = {
        bindings = {
          "ctrl-b" = "workspace::ToggleRightDock";
        };
      };
    };
  };
}
