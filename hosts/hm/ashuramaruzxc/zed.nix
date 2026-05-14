{
  config,
  lib,
  pkgs,
  ...
}:
let
  codexHome = "${config.home.homeDirectory}/.codex";
  codexOpenrouterEnvFile = config.sops.templates."codex-openrouter.env".path;

  codexAcpOpenrouter = pkgs.writeShellApplication {
    name = "codex-acp-openrouter";
    text = ''
      set -a
      # shellcheck disable=SC1091
      . ${lib.escapeShellArg codexOpenrouterEnvFile}
      set +a

      exec ${lib.getExe pkgs.codex-acp} "$@"
    '';
  };

  openrouterArgs = [
    "-c"
    "model_provider=\"openrouter\""
    "-c"
    "model=\"deepseek/deepseek-v4-pro\""
    "-c"
    "model_catalog_json=\"${codexHome}/openrouter-model-catalog.json\""
    "-c"
    "model_reasoning_effort=\"high\""
    "-c"
    "model_context_window=1000000"
    "-c"
    "model_auto_compact_token_limit=950000"
    "-c"
    "model_supports_reasoning_summaries=false"
    "-c"
    "service_tier=\"fast\""
  ];
in
{
  sops.secrets.openrouter_api_key = { };

  sops.templates."codex-openrouter.env".content = ''
    OPENROUTER_API_KEY=${config.sops.placeholder.openrouter_api_key}
  '';

  programs.zed-editor.extensions = [
    "docker-compose"
    "dockerfile"
    "emmet"
    "git-firefly"
    "github-actions"
    "graphql"
    "mcp-server-context7"
    "mcp-server-github"
    "prisma"
  ];

  programs.zed-editor.userSettings = {
    agent = {
      default_model = {
        enable_thinking = true;
        model = "deepseek/deepseek-v4-pro";
        provider = "openrouter";
      };
      dock = "right";
      favorite_models = [
        {
          model = "deepseek/deepseek-v4-pro";
          provider = "openrouter";
        }
      ];
      model_parameters = [ ];
      sidebar_side = "right";
    };

    agent_servers = {
      # cline = {
      #   type = "custom";
      #   command = lib.getExe pkgs.cline;
      #   args = [ "--acp" ];
      #   env = { };
      # };

      "codex-acp" = {
        type = "custom";
        command = lib.getExe pkgs.codex-acp;
        args = [ ];
        env.CODEX_HOME = codexHome;
      };

      codex_openrouter = {
        type = "custom";
        command = lib.getExe codexAcpOpenrouter;
        args = openrouterArgs;
        env.CODEX_HOME = codexHome;
      };
    };

    context_servers = {
      "mcp-server-context7" = {
        settings = { };
      };

      "mcp-server-github" = {
        settings = { };
      };

      openaiDeveloperDocs.url = "https://developers.openai.com/mcp";
    };

    autosave.after_delay.milliseconds = 1000;

    cli_default_open_behavior = "existing_window";
    diff_view_style = "unified";
    disable_ai = false;
    edit_predictions.provider = "zed";
    format_on_save = "on";
    show_edit_predictions = false;

    collaboration_panel = {
      dock = "left";
    };
    git_panel.dock = "right";
    outline_panel.dock = "left";
    project_panel = {
      dock = "right";
    };

    buffer_font_family = "MesloLGL Nerd Font";
    buffer_font_size = 18;
    colorize_brackets = true;
    ensure_final_newline_on_save = true;
    preferred_line_length = 120;
    remove_trailing_whitespace_on_save = true;
    semantic_tokens = "combined";
    show_whitespaces = "selection";
    soft_wrap = "editor_width";
    tab_size = 2;
    title_bar.button_layout = "platform_default";
    ui_font_family = "NotoSans Nerd Font Propo";
    ui_font_size = 18;

    terminal = {
      blinking = "on";
      cursor_shape = "bar";
      font_family = "Hack Nerd Font";
      font_size = 16;
      minimum_contrast = 0;
    };

    context.Workspace.bindings."ctrl-b" = "workspace::ToggleRightDock";
  };
}
