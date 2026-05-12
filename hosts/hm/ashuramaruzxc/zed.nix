{ lib, pkgs, ... }:
{
  programs.zed-editor.extensions = [
    "dockerfile"
    "docker-compose"
    "emmet"
    "git-firefly"
    "github-actions"
    "graphql"
    "prisma"
  ];

  programs.zed-editor.userSettings = {
    agent_servers."codex-acp" = {
      type = "custom";
      command = lib.getExe pkgs.codex-acp;
      args = [ ];
      env = { };
    };
    context_servers.openaiDeveloperDocs = {
      url = "https://developers.openai.com/mcp";
    };
    autosave = {
      after_delay.milliseconds = 1000;
    };
    buffer_font_family = "MesloLGL Nerd Font";
    buffer_font_size = 18;
    colorize_brackets = true;
    ensure_final_newline_on_save = true;
    format_on_save = "on";
    preferred_line_length = 120;
    project_panel = {
      dock = "right";
    };
    remove_trailing_whitespace_on_save = true;
    semantic_tokens = "combined";
    show_whitespaces = "selection";
    soft_wrap = "editor_width";
    tab_size = 2;
    title_bar = {
      button_layout = "platform_default";
    };
    terminal = {
      blinking = "on";
      cursor_shape = "bar";
      font_family = "Hack Nerd Font";
      font_size = 16;
      minimum_contrast = 0;
    };
    ui_font_family = "NotoSans Nerd Font Propo";
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
