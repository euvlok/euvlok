{ pkgs, ... }: {
  programs.zed-editor = {
    installRemoteServer = true;
    package = pkgs.unstable.zed-editor;

    extensions = [
      "docker-compose"
      "dockerfile"
      "emmet"
      "git-firefly"
      "github-actions"
      "graphql"
      "prisma"
    ];

    userSettings = {
      autosave.after_delay.milliseconds = 1000;

      buffer_font_family = "MesloLGL Nerd Font";
      buffer_font_size = 18;

      cli_default_open_behavior = "existing_window";
      collaboration_panel.dock = "left";
      colorize_brackets = true;

      context.Workspace.bindings."ctrl-b" = "workspace::ToggleRightDock";
      diff_view_style = "unified";
      ensure_final_newline_on_save = true;
      format_on_save = "on";

      git_panel.dock = "right";
      outline_panel.dock = "left";
      preferred_line_length = 120;
      project_panel.dock = "right";
      remove_trailing_whitespace_on_save = true;
      semantic_tokens = "combined";
      show_whitespaces = "selection";
      soft_wrap = "editor_width";
      tab_size = 2;

      terminal = {
        blinking = "on";
        cursor_shape = "bar";
        font_family = "Hack Nerd Font";
        font_size = 16;
        minimum_contrast = 0;
      };

      title_bar.button_layout = "platform_default";
      ui_font_family = "NotoSans Nerd Font Propo";
      ui_font_size = 18;
    };
  };
}
