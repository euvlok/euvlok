{
  config,
  lib,
  pkgs,
  ...
}:
let
  zed = config.programs.zed-editor;
  subscribedModel = {
    inherit (config.programs.codex.settings) model;
    enable_thinking = true;
    effort = config.programs.codex.settings.model_reasoning_effort;
    provider = "openai-subscribed";
  };
in
{
  # Zed's mutable settings merge retains keys removed from older generations.
  home.activation.removeRetiredZedIntegrations =
    lib.modules.mkIf (zed.enable && zed.mutableUserSettings)
      (
        lib.hm.dag.entryAfter [ "zedSettingsActivation" ] (
          lib.hm.generators.mkImpureConfigMerger {
            inherit pkgs;
            path = "${config.xdg.configHome}/zed/settings.json";
            format = "json";
            empty = "{}";
            staticSettings = (pkgs.formats.json { }).generate "retired-zed-extensions.json" {
              mcp-server-context7 = false;
              mcp-server-github = false;
            };
            jqOperation = ''
              $dynamic
              | if .agent_servers == null then .
                else del(.agent_servers."codex-acp", .agent_servers.codex_openrouter) end
              | delpaths($static | keys | map(["context_servers", .]))
              | .auto_install_extensions += $static
            '';
          }
        )
      );

  programs.zed-editor = {
    enableMcpIntegration = true;
    installRemoteServer = true;
    package = pkgs.unstable.zed-editor;

    extensions = [
      "docker-compose"
      "dockerfile"
      "emmet"
      "git-firefly"
      "github-actions"
      "graphql"
    ];

    userKeymaps = [
      {
        context = "Workspace";
        bindings."ctrl-b" = "workspace::ToggleRightDock";
      }
    ];

    userSettings = {
      agent = {
        dock = "right";
        model_parameters = [ ];
        sandbox_permissions.allow_unsandboxed = true;
        threads_sidebar.position = "right";
      }
      // lib.attrsets.optionalAttrs config.euvlok.home.codex.enable {
        default_model = subscribedModel;
        favorite_models = [ subscribedModel ];
      };

      autosave.after_delay.milliseconds = 1000;

      buffer_font_family = "MesloLGL Nerd Font";
      buffer_font_size = 18;

      cli_default_open_behavior = "existing_window";
      collaboration_panel.dock = "left";
      colorize_brackets = true;

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
