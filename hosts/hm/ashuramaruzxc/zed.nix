{
  config,
  inputs,
  lib,
  osConfig ? null,
  pkgs,
  ...
}:
let
  zedEditor =
    (import inputs.nixpkgs-master {
      inherit (pkgs.stdenv.hostPlatform) system;
      inherit (pkgs) config;
    }).zed-editor;

  codexAcpOpenrouter = pkgs.writeShellApplication {
    name = "codex-acp-openrouter";
    runtimeInputs = [ pkgs.codex-acp ];
    text = ''
      set -a
      # shellcheck disable=SC1091
      . ${lib.strings.escapeShellArg config.sops.templates."codex-openrouter.env".path}
      set +a

      exec codex-acp "$@"
    '';
  };

  openrouterArgs =
    lib.lists.concatMap
      (arg: [
        "-c"
        arg
      ])
      [
        "model_provider=\"openrouter\""
        "model=\"deepseek/deepseek-v4-pro\""
        "model_catalog_json=\"${config.home.homeDirectory}/.codex/openrouter-model-catalog.json\""
        "model_reasoning_effort=\"high\""
        "model_context_window=1000000"
        "model_auto_compact_token_limit=950000"
        "model_supports_reasoning_summaries=false"
        "service_tier=\"fast\""
      ];
in
lib.modules.mkMerge [
  {
    programs.zed-editor = {
      enableMcpIntegration = true;
      installRemoteServer = true;
      package = zedEditor;
      extraPackages = [
        pkgs.codex-acp
      ];

      extensions = [
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

      userSettings = {
        agent = {
          dock = "right";
          model_parameters = [ ];
          sidebar_side = "right";
        };

        agent_servers = {
          # cline = {
          #   type = "custom";
          #   command = lib.meta.getExe' pkgs.eupkgs.cline-ai "cline";
          #   args = [ "--acp" ];
          #   env = { };
          # };

          "codex-acp" = {
            type = "custom";
            command = "codex-acp";
            args = [ ];
            env.CODEX_HOME = "${config.home.homeDirectory}/.codex";
          };
        };

        autosave.after_delay.milliseconds = 1000;

        buffer_font_family = "MesloLGL Nerd Font";
        buffer_font_size = 18;

        cli_default_open_behavior = "existing_window";
        collaboration_panel.dock = "left";
        colorize_brackets = true;

        context.Workspace.bindings."ctrl-b" = "workspace::ToggleRightDock";
        context_servers = {
          "mcp-server-context7".settings = { };
          "mcp-server-github".settings = { };
          openaiDeveloperDocs.url = "https://developers.openai.com/mcp";
        };

        diff_view_style = "unified";
        disable_ai = false;
        edit_predictions.provider = "zed";
        ensure_final_newline_on_save = true;
        format_on_save = "on";

        git_panel.dock = "right";
        outline_panel.dock = "left";
        preferred_line_length = 120;
        project_panel.dock = "right";
        remove_trailing_whitespace_on_save = true;
        semantic_tokens = "combined";
        show_edit_predictions = false;
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

  (lib.modules.mkIf (osConfig != null && osConfig.networking.hostName == "unsigned-int32") {
    sops.secrets.openrouter_api_key = { };

    sops.templates."codex-openrouter.env".content = ''
      OPENROUTER_API_KEY=${config.sops.placeholder.openrouter_api_key}
    '';

    programs.zed-editor = {
      extraPackages = [ codexAcpOpenrouter ];

      userSettings = {
        agent = {
          default_model = {
            enable_thinking = true;
            effort = "medium";
            model = "gpt-5.5";
            provider = "openai-subscribed";
          };
          favorite_models = [
            {
              enable_thinking = true;
              effort = "medium";
              model = "gpt-5.5";
              provider = "openai-subscribed";
            }
            {
              model = "deepseek/deepseek-v4-pro";
              provider = "openrouter";
            }
          ];
        };

        agent_servers.codex_openrouter = {
          type = "custom";
          command = "codex-acp-openrouter";
          args = openrouterArgs;
          env.CODEX_HOME = "${config.home.homeDirectory}/.codex";
        };
      };
    };
  })
]
