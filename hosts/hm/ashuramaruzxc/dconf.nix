{ lib, ... }:
let
  # Configuration variables
  numWorkspaces = 6;
  defaultFontSize = 11;

  # Generate numbered keybindings (e.g., Super+1 through Super+6 for workspace switching)
  # prefix: the base name for the keybinding (e.g., "switch-to-workspace")
  # super: the super key modifier (e.g., "<Super>")
  # modifiers: additional modifiers as a list (e.g., ["<Shift>"])
  # range: number of keybindings to generate
  generateKeybindings =
    prefix: super: modifiers: range:
    builtins.listToAttrs (
      builtins.genList (
        x:
        let
          num = toString (x + 1);
          modifierStr = builtins.concatStringsSep "" modifiers;
        in
        {
          name = "${prefix}-${num}";
          value = [ "${super}${modifierStr}${num}" ];
        }
      ) range
    );
in
{
  dconf.settings = {
    # App Switcher Configuration
    "org/gnome/shell/app-switcher".current-workspace-only = true;

    # Keyboard & Sound Settings
    "org/gnome/settings-daemon/peripherals/keyboard".bell-mode = "off";
    "org/gnome/desktop/sound".allow-volume-above-100-percent = true;

    # Mouse Configuration
    "org/gnome/desktop/peripherals/mouse".accel-profile = "flat";

    # Interface & Appearance
    "org/gnome/desktop/interface" = {
      clock-format = "24h";
      clock-show-date = true;
      clock-show-seconds = true;
      document-font-name = "Noto Sans ${toString defaultFontSize}";
      font-hinting = "slight";
      monospace-font-name = "Hack Nerd Font Mono Regular ${toString defaultFontSize}";
    };

    # Window Manager Preferences
    "org/gnome/desktop/wm/preferences" = {
      titlebar-font = "Noto Sans Medium, ${toString defaultFontSize}";
      num-workspaces = numWorkspaces;
      resize-with-right-button = true;
      audible-bell = false;
    };

    # Mutter Configuration (compositor)
    "org/gnome/mutter" = {
      dynamic-workspaces = false;
      workspace-only-on-primary = true;
      experimental-features = [
        "scale-monitor-framebuffer"
        "variable-refresh-rate"
        "xwayland-native-scaling"
      ];
    };
    # Shell Keybindings - Disable default app switcher keybindings (Super+1-9)
    "org/gnome/shell/keybindings" = lib.genAttrs (map (n: "switch-to-application-${toString n}") (
      lib.range 1 9
    )) (_: [ ]);

    # Mutter Keybindings - Window tiling shortcuts
    "org/gnome/mutter/keybindings" = {
      move-to-center = [ "<Super>Return" ];
      toggle-tiled-left = [ "<Super>a" ];
      toggle-tiled-right = [ "<Super>d" ];
    };

    # Window Manager Keybindings
    "org/gnome/desktop/wm/keybindings" =
      let
        manualKeybindings = {
          maximize = [ "<Super><Shift>Return" ];
          move-to-side-n = [ "<Super>w" ];
          move-to-side-s = [ "<Super>s" ];
          toggle-fullscreen = [ "<Alt>F11" ];
          toggle-maximized = [ "<Alt>F10" ];
        };
        # Generate Super+1-6 for workspace switching
        switchKeybindings = generateKeybindings "switch-to-workspace" "<Super>" [ ] numWorkspaces;
        # Generate Super+Shift+1-6 for moving windows to workspaces
        moveKeybindings = generateKeybindings "move-to-workspace" "<Super>" [ "<Shift>" ] numWorkspaces;
      in
      lib.mkMerge [
        manualKeybindings
        switchKeybindings
        moveKeybindings
      ];
    # GNOME Shell Extensions
    "org/gnome/shell" = {
      enabled-extensions = [
        "appindicatorsupport@rgcjonas.gmail.com"
        "arcmenu@arcmenu.com"
        "auto-move-windows@gnome-shell-extensions.gcampax.github.com"
        "clipboard-indicator@tudmotu.com"
        "dash-to-dock@micxgx.gmail.com"
        "dash-to-panel@jderose9.github.com"
        "gsconnect@andyholmes.github.io"
        "kimpanel@kde.org"
        "pop-shell@system76.com"
        "system-monitor@gnome-shell-extensions.gcampax.github.com"
        "user-theme@gnome-shell-extensions.gcampax.github.com"
      ];
    };
  };
}
