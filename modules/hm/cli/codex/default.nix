{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.euvlok.home.codex;
  inherit (pkgs.stdenvNoCC.hostPlatform) isDarwin;

  codexConfigDir =
    if config.home.preferXdgDirectories then
      "${lib.strings.removePrefix config.home.homeDirectory config.xdg.configHome}/codex"
    else
      ".codex";

  codexShellAliases = {
    cx = "command codex --sandbox danger-full-access --ask-for-approval never";
  };

  codexSettings = {
    model = "gpt-5.6-sol";
    model_reasoning_effort = "high";
    approval_policy = "never";
    default_permissions = "unrestricted";
    web_search = "live";
    check_for_update_on_startup = lib.modules.mkDefault false;
    suppress_unstable_features_warning = true;
    tool_output_token_limit = lib.modules.mkDefault (32 * 1024);

    permissions.unrestricted = {
      description = "Unrestricted access without the desktop Full access warning";
      filesystem = {
        ":root" = "write";
      };
      network = {
        enabled = true;
        allow_local_binding = true;
        dangerously_allow_all_unix_sockets = true;
      };
    };

    tui = {
      notification_condition = lib.modules.mkDefault "always";
      show_tooltips = false;
      terminal_resize_reflow_max_rows = 0;
      status_line_use_colors = lib.modules.mkDefault true;
      status_line = lib.modules.mkDefault [
        "model-with-reasoning"
        "project-name"
        "context-remaining"
        "five-hour-limit"
        "weekly-limit"
      ];
      keymap.global = {
        open_external_editor = "ctrl-x";
      }
      // lib.attrsets.optionalAttrs isDarwin {
        open_transcript = "ctrl-t";
      };
    }
    // lib.attrsets.optionalAttrs config.catppuccin.enable {
      theme = lib.modules.mkDefault "catppuccin-frappe-pink";
    };

    features.prevent_idle_sleep = lib.modules.mkDefault true;

    apps._default = {
      enabled = true;
      destructive_enabled = true;
      open_world_enabled = true;
      default_tools_approval_mode = "approve";
    };

    notice = {
      hide_full_access_warning = true;
      hide_world_writable_warning = true;
    };
  };
in
{
  options.euvlok.home.codex.enable = lib.options.mkEnableOption "Codex";

  config = lib.modules.mkIf cfg.enable {
    euvlok.home.opencode.enable = lib.modules.mkDefault true;

    home.packages = [ pkgs.unstable.codex-acp ];

    programs.codex = {
      enable = true;
      package = pkgs.unstable.codex;
      settings = codexSettings;
      profiles = {
        review = {
          approval_policy = "never";
          default_permissions = ":read-only";
          web_search = "cached";
          apps._default.enabled = false;
          features.apps = false;
        };
        safe = {
          approval_policy = "on-request";
          default_permissions = ":workspace";
          web_search = "cached";
          apps._default.default_tools_approval_mode = "writes";
        };
      };
    };

    programs.bash.shellAliases = codexShellAliases;
    programs.fish.shellAliases = codexShellAliases;
    programs.zsh.shellAliases = codexShellAliases;

    home.file = lib.attrsets.optionalAttrs config.catppuccin.enable {
      "${codexConfigDir}/themes/catppuccin-frappe-pink.tmTheme".source = ./catppuccin-frappe-pink.tmTheme;
    };
  };
}
