{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.euvlok.home.codex;
  desktopEnabled = config.programs.codexDesktopLinux.enable or false;
  gitlabEnvEnabled = config.sops.secrets ? gitlab_token || config.sops.secrets ? gitlab_host;
  context7KeyEnabled = config.sops.secrets ? context7_api_key;
  inherit (config.catppuccin) accent flavor;
  inherit (pkgs.stdenvNoCC.hostPlatform) isDarwin;

  gitlabMcp = pkgs.writeShellApplication {
    name = "codex-gitlab-mcp";
    text = ''
      set -a
      # shellcheck disable=SC1091
      . ${lib.strings.escapeShellArg config.sops.templates."codex-gitlab.env".path}
      set +a

      exec ${lib.meta.getExe pkgs.unstable.glab} "$@"
    '';
  };

  palette = lib.trivial.importJSON "${config.catppuccin.sources.palette}/palette.json";
  lightColors = palette.latte.colors;
  darkColors = palette.${flavor}.colors;
  terminalFont = "Hack Nerd Font Mono";

  mkDesktopTheme = colors: contrast: {
    inherit contrast;
    accent = colors.${accent}.hex;
    ink = colors.text.hex;
    surface = colors.base.hex;
    opaqueWindows = false;
    fonts.code = terminalFont;
    semanticColors = {
      diffAdded = colors.green.hex;
      diffRemoved = colors.red.hex;
      skill = colors.${accent}.hex;
    };
  };
in
{

  config = lib.modules.mkIf cfg.enable {
    programs.ghostty.settings.font-family = terminalFont;

    home.packages = [ pkgs.unstable.glab ];

    home.file.".agents/skills/glab".source =
      "${pkgs.unstable.glab.src}/internal/commands/skills/bundled/assets/glab";

    sops.templates."codex-gitlab.env" = lib.modules.mkIf gitlabEnvEnabled {
      content =
        lib.strings.optionalString (config.sops.secrets ? gitlab_token) ''
          GITLAB_TOKEN='${config.sops.placeholder.gitlab_token}'
        ''
        + lib.strings.optionalString (config.sops.secrets ? gitlab_host) ''
          GITLAB_HOST='${config.sops.placeholder.gitlab_host}'
        '';
    };

    sops.templates."codex-context7-headers.json" = lib.modules.mkIf context7KeyEnabled {
      content = builtins.toJSON {
        Authorization = "Bearer ${config.sops.placeholder.context7_api_key}";
      };
    };

    programs.codex.settings = {
      personality = "pragmatic";
      model = "gpt-6-astra";
      model_reasoning_effort = "high";
      plan_mode_reasoning_effort = "high";
      approvals_reviewer = "auto_review";
      check_for_update_on_startup = false;
      web_search = "live";
      history.persistence = "save-all";
      project_doc_fallback_filenames = [ "CLAUDE.md" ];

      analytics.enabled = false;

      plugins = lib.modules.mkIf desktopEnabled (
        lib.attrsets.genAttrs
          [
            "browser@openai-bundled"
            "chrome@openai-bundled"
            "visualize@openai-bundled"
            "deep-research@openai-bundled"
            "latex@openai-bundled"
          ]
          (_: {
            enabled = true;
          })
      );

      apps = lib.modules.mkIf desktopEnabled {
        connector_76869538009648d5b282a4bb21c3d157.enabled = true; # GitHub
        connector_0c9786b2f41f41558056126bdb46c9bd.enabled = true; # GitLab
      };

      hooks.state = {
        "${config.home.homeDirectory}/.codex/hooks.json:session_start:0:0".enabled = false;
      };

      memories = {
        generate_memories = true;
        use_memories = true;
        disable_on_external_context = false;
        min_rate_limit_remaining_percent = 10;
        min_rollout_idle_hours = 2;
        max_rollouts_per_startup = 32;
        max_rollout_age_days = 90;
        max_unused_days = 180;
        max_raw_memories_for_consolidation = 512;
      };

      mcp_servers = {
        context7 = {
          url = "https://mcp.context7.com/mcp";
          http_headers_helper = lib.modules.mkIf context7KeyEnabled (
            "${pkgs.coreutils}/bin/cat "
            + lib.strings.escapeShellArg config.sops.templates."codex-context7-headers.json".path
          );
          enabled = true;
          startup_timeout_sec = 20;
          tool_timeout_sec = 60;
          default_tools_approval_mode = "auto";
        };

        gitlab = {
          command = lib.meta.getExe (if gitlabEnvEnabled then gitlabMcp else pkgs.unstable.glab);
          args = [
            "mcp"
            "serve"
          ];
          env_vars = [
            "GITLAB_HOST"
            "GITLAB_TOKEN"
            "GLAB_CONFIG_DIR"
          ];
          enabled = true;
          startup_timeout_sec = 20;
          tool_timeout_sec = 120;
          default_tools_approval_mode = "auto";
        };
      };

      projects = {
        "${config.home.homeDirectory}".trust_level = "trusted";
        "${config.home.homeDirectory}/Documents/work".trust_level = "trusted";
        "${config.home.homeDirectory}/Documents/work/ansible".trust_level = "trusted";
        "${config.home.homeDirectory}/Documents/work/development".trust_level = "trusted";
        "/etc/nixos".trust_level = "trusted";
      };

      features = {
        apps = true;
        goals = true;
        hooks = true;
        image_generation = true;
        memories = true;
        multi_agent = true;
        prevent_idle_sleep = true;
        remote_plugin = true;
        skill_mcp_dependency_install = true;
        terminal_resize_reflow = true;
        undo = true;
      };

      tui = {
        notification_condition = "unfocused";
        show_tooltips = false;
        status_line_use_colors = true;
        status_line = [
          "run-state"
          "project-name"
          "git-branch"
          "branch-changes"
          "pull-request-number"
          "model-with-reasoning"
          "permissions"
          "task-progress"
          "context-remaining"
          "five-hour-limit"
          "weekly-limit"
        ];
        terminal_title = [
          "thread-title"
          "task-progress"
          "current-dir"
          "git-branch"
          "model"
        ];
        theme = "catppuccin-${flavor}";
        keymap.global = {
          open_external_editor = "ctrl-x";
        }
        // lib.attrsets.optionalAttrs isDarwin {
          open_transcript = "ctrl-t";
        };
      };

      desktop = {
        ambient-suggestions-enabled = false;
        conversationDetailMode = "STEPS_COMMANDS";
        followUpQueueMode = "queue";
        show-context-window-usage = true;
        show-educational-tips = false;
        open-local-url-in-target-preference = "external-browser";
        show-ultra-in-model-picker-slider = false;
        appearanceDiffMarkerStyle = "symbols";
        reviewDelivery = "inline";
        git-review-mode = "full";
        git-show-sidebar-pr-icons = true;

        notifications-turn-mode = "unfocused";
        notifications-permissions-enabled = true;
        notifications-questions-enabled = true;

        appearanceLightCodeThemeId = "catppuccin";
        appearanceDarkCodeThemeId = "catppuccin";
        sansFontSize = 15;
        codeFontSize = 13;
        defaultTerminalLocation = "bottom";
        preventSleepWhileRunning = true;
        appearanceTheme = "system";
        usePointerCursors = true;
        reduced-motion-preference = "on";
        appearanceLightChromeTheme = mkDesktopTheme lightColors 45;
        appearanceDarkChromeTheme = mkDesktopTheme darkColors 60;
      };
    };
  };
}
