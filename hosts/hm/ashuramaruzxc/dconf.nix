{ lib, ... }:
let
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
    "org/gnome/shell/app-switcher".current-workspace-only = true;
    "org/gnome/settings-daemon/peripherals/keyboard".bell-mode = "off";
    "org/gnome/desktop/interface" = {
      clock-format = "24h";
      clock-show-date = true;
      clock-show-seconds = true;
      document-font-name = "Noto Sans 11";
      font-hinting = "slight";
      monospace-font-name = "Hack Nerd Font Mono Regular 11";
    };
    "org/gnome/desktop/sound".allow-volume-above-100-percent = true;
    "org.gnome.desktop.peripherals/mouse".accel-profile = "flat";
    "org/gnome/desktop/wm/preferences" = {
      titlebar-font = "Noto Sans Medium, 11";
      num-workspaces = 6;
      resize-with-right-button = true;
      audible-bell = false;
    };
    "org/gnome/mutter" = {
      dynamicWorkspaces = false;
      workspace-only-on-primary = true;
      experimental-features = [
        "variable-refresh-rate"
        "scale-monitor-framebuffer"
        "xwayland-native-scaling"
      ];
    };
    "org/gnome/shell/keybindings" =
      let
        otherKeybindings = { };
        switchKeybindings = (
          lib.genAttrs (map (n: "switch-to-application-${toString n}") (lib.range 1 9)) (_: [ ])
        );
      in
      lib.mkMerge [
        otherKeybindings
        switchKeybindings
      ];

    "org/gnome/mutter/keybindings" = {
      toggle-tiled-left = [ "<Super>a" ];
      toggle-tiled-right = [ "<Super>d" ];
      move-to-center = [ "<Super>Return" ];
    };

    "org/gnome/desktop/wm/keybindings" =
      let
        otherKeybindings = {
          maximize = [ "<Super><Shift>Return" ];
          move-to-side-n = [ "<Super>w" ];
          move-to-side-s = [ "<Super>s" ];
          toggle-maximized = [ "<Alt>F10" ];
          toggle-fullscreen = [ "<Alt>F11" ];
        };
        switchKeybindings = generateKeybindings "switch-to-workspace" "<Super>" [ ] 6;
        moveKeybindings = generateKeybindings "move-to-workspace" "<Super>" [ "<Shift>" ] 6;
      in
      lib.mkMerge [
        otherKeybindings
        switchKeybindings
        moveKeybindings
      ];
    "org/gnome/shell" = {
      enabled-extensions = [
        "appindicatorsupport@rgcjonas.gmail.com"
        "arcmenu@arcmenu.com"
        "clipboard-indicator@tudmotu.com"
        "dash-to-dock@micxgx.gmail.com"
        "dash-to-panel@jderose9.github.com"
        "gsconnect@andyholmes.github.io"
        "kimpanel@kde.org"
        "pop-shell@system76.com"
        "system-monitor@gnome-shell-extensions.gcampax.github.com"
        "auto-move-windows@gnome-shell-extensions.gcampax.github.com"
      ];
    };
  };
}
