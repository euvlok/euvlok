{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.euvlok.home.codex;
  inherit (config.catppuccin) accent flavor;
  inherit (pkgs.stdenvNoCC.hostPlatform) isDarwin;

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

    programs.codex.settings = {
      personality = "pragmatic";
      model = "gpt-5.6-sol";
      model_reasoning_effort = "high";
      approvals_reviewer = "auto_review";
      check_for_update_on_startup = false;
      service_tier = "fast";
      web_search = "live";

      history = {
        persistence = "save-all";
        max_bytes = 104857600;
      };
      project_doc_max_bytes = 131072;
      project_doc_fallback_filenames = [ "CLAUDE.md" ];
      tool_output_token_limit = 25000;

      analytics.enabled = false;

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
        nixos = {
          command = lib.meta.getExe pkgs.mcp-nixos;
          enabled = true;
          startup_timeout_sec = 20;
          tool_timeout_sec = 120;
          default_tools_approval_mode = "auto";
        };

        context7 = {
          url = "https://mcp.context7.com/mcp";
          enabled = true;
          startup_timeout_sec = 20;
          tool_timeout_sec = 60;
          default_tools_approval_mode = "auto";
        };

        openaiDeveloperDocs = {
          url = "https://developers.openai.com/mcp";
          enabled = true;
          startup_timeout_sec = 20;
          tool_timeout_sec = 60;
          default_tools_approval_mode = "auto";
        };
      };

      projects = {
        "${config.home.homeDirectory}".trust_level = "trusted";
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
