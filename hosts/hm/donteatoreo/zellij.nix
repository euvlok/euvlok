{
  pkgsUnstable,
  lib,
  config,
  osConfig,
  eulib,
  ...
}:
let
  inherit (osConfig.nixpkgs.hostPlatform) isDarwin;
  inherit (eulib)
    mkBind
    mkShiftBind
    mkSimpleBind
    mkDirectionalNewPane
    mkDirectionalResize
    mkModeSwitch
    ;

  modKey = if isDarwin then "Super" else "Ctrl";
in
{
  programs.zellij.settings = {
    default_shell = lib.mkForce "${lib.getExe pkgsUnstable.nushell}";

    # UI customizations
    ui = {
      pane_frames = {
        rounded_corners = true;
        hide_session_name = false;
      };
    };

    default_layout = "compact";

    # Session mode keybinds
    session = lib.mkMerge [
      (mkSimpleBind "d" {
        Detach = { };
        SwitchToMode = "Normal";
      })
      (mkSimpleBind "w" {
        LaunchOrFocusPlugin = "session-manager";
        SwitchToMode = "Normal";
      })
      (mkSimpleBind "Esc" { SwitchToMode = "Normal"; })
    ];

    # Plugin configuration
    plugins = {
      tab-bar = {
        path = "tab-bar";
      };
      strider = {
        path = "strider";
      };
      compact-bar = {
        path = "compact-bar";
      };
      session-manager = {
        path = "session-manager";
      };
      status-bar = {
        path = "status-bar";
      };
    };

    # Advanced keybinds
    keybinds = {
      normal = lib.mkMerge [
        # Advanced bindings
        (mkShiftBind { inherit modKey; } "Backspace" { CloseFocus = { }; }) # Close pane
        (mkShiftBind { inherit modKey; } "r" { SwitchToMode = "Resize"; }) # Resize mode
        (mkShiftBind { inherit modKey; } "s" { SwitchToMode = "Pane"; }) # Pane mode
        (mkModeSwitch modKey "s" "Search")
        (mkModeSwitch modKey "o" "Session")
      ];

      # Pane mode (Super+Shift+s > direction)
      pane = lib.mkMerge [
        mkDirectionalNewPane
        (mkSimpleBind "p" { SwitchFocus = { }; })
        (mkSimpleBind "x" {
          CloseFocus = { };
          SwitchToMode = "Normal";
        })
        (mkSimpleBind "f" {
          ToggleFocusFullscreen = { };
          SwitchToMode = "Normal";
        })
        (mkSimpleBind "Esc" { SwitchToMode = "Normal"; })
      ];

      # Resize mode (Super+Shift+r > direction)
      resize = lib.mkMerge [
        mkDirectionalResize
        (mkSimpleBind "=" {
          Resize = "Increase";
          SwitchToMode = "Normal";
        })
        (mkSimpleBind "-" {
          Resize = "Decrease";
          SwitchToMode = "Normal";
        })
        (mkSimpleBind "Esc" { SwitchToMode = "Normal"; })
      ];

      # Search mode
      search = lib.mkMerge [
        (mkSimpleBind "/" {
          SwitchToMode = "EnterSearch";
          SearchInput = 0;
        })
        (mkSimpleBind "n" { Search = "down"; })
        (mkSimpleBind "N" { Search = "up"; })
        (mkSimpleBind "c" { SearchToggleOption = "CaseSensitivity"; })
        (mkSimpleBind "w" { SearchToggleOption = "WholeWord"; })
        (mkSimpleBind "e" {
          EditScrollback = { };
          SwitchToMode = "Normal";
        })
        (mkSimpleBind "Esc" { SwitchToMode = "Normal"; })
      ];
    };
  };
}
