{ config, pkgs, ... }:
{
  # imports = [ niri.homeModules.config ];
  home.packages = builtins.attrValues {
    inherit (pkgs)
      apostrophe # Markdown Editor
      decibels # Audio Player
      loupe # Image Viewer
      showtime # Video Player
      wl-clipboard
      nautilus
      baobab
      ;
    inherit (pkgs)
      xwayland-satellite
      hyprpaper
      pavucontrol
      ;
  };

  programs.niri = {
    package = pkgs.niri;
    settings = {
      prefer-no-csd = true;
      overview.workspace-shadow.enable = false;

      input = {
        keyboard = {
          xkb.layout = "pl";
          numlock = true;
        };

        touchpad = {
          tap = true;
          natural-scroll = false;
        };
      };

      layout = {
        gaps = 16;
        background-color = "transparent";
        center-focused-column = "on-overflow";
        always-center-single-column = true;
        preset-column-widths = [
          { proportion = 0.33333; }
          { proportion = 0.5; }
          { proportion = 0.66667; }
          { proportion = 1.0; }
        ];
        default-column-width = {
          proportion = 0.66667;
        };
        focus-ring.enable = false;
        border.width = 4;
        shadow = {
          softness = 30;
          spread = 5;
          offset = {
            x = 0;
            y = 5;
          };
          color = "#0007";
        };
      };

      outputs."HDMI-A-1" = {
        scale = 1.0;
        focus-at-startup = true;
        mode = {
          height = 1080;
          refresh = 100.000;
          width = 1920;
        };
      };

      layer-rules = [
        {
          matches = [ { namespace = "^noctalia-wallpaper*"; } ];
          place-within-backdrop = true;
        }
      ];

      window-rules = [
        {
          geometry-corner-radius =
            let
              radius = 10.0;
            in
            {
              bottom-left = radius;
              bottom-right = radius;
              top-left = radius;
              top-right = radius;
            };
          clip-to-geometry = true;
        }
      ];
    };
    settings.spawn-at-startup = [
      {
        command = [
          "noctalia-shell"
        ];
      }
    ];
    settings.binds = with config.lib.niri.actions; {
      "Super+Q".action = spawn "ghostty";
      "Super+R".action = spawn "vicinae" "toggle";
      "Super+E".action = spawn "nautilus";
      "Super+C".action = close-window;
      "Super+M".action = quit;
      "Super+D".action = switch-preset-column-width;
      "Super+V".action = toggle-window-floating;
      "Super+F".action = toggle-overview;
      "Super+Space".action = switch-layout "next";

      "Super+Comma".action = consume-window-into-column;
      "Super+Period".action = expel-window-from-column;
      "Super+BracketLeft".action = consume-or-expel-window-left;
      "Super+BracketRight".action = consume-or-expel-window-right;

      "Super+WheelScrollDown" = {
        action = focus-workspace-down;
        cooldown-ms = 150;
      };
      "Super+WheelScrollUp" = {
        action = focus-workspace-up;
        cooldown-ms = 150;
      };
      "Super+Ctrl+WheelScrollDown" = {
        action = move-column-to-workspace-down;
        cooldown-ms = 150;
      };
      "Super+Ctrl+WheelScrollUp" = {
        action = move-column-to-workspace-up;
        cooldown-ms = 150;
      };

      "Super+WheelScrollRight".action = focus-column-right;
      "Super+WheelScrollLeft".action = focus-column-left;
      "Super+Ctrl+WheelScrollRight".action = move-column-right;
      "Super+Ctrl+WheelScrollLeft".action = move-column-left;

      "Super+Shift+WheelScrollDown".action = focus-column-right;
      "Super+Shift+WheelScrollUp".action = focus-column-left;
      "Super+Ctrl+Shift+WheelScrollDown".action = move-column-right;
      "Super+Ctrl+Shift+WheelScrollUp".action = move-column-left;

      "Super+1".action.focus-workspace = 1;
      "Super+2".action.focus-workspace = 2;
      "Super+3".action.focus-workspace = 3;

      "Super+Shift+1".action.move-column-to-workspace = 1;
      "Super+Shift+2".action.move-column-to-workspace = 2;
      "Super+Shift+3".action.move-column-to-workspace = 3;

      "Super+Left".action = focus-column-left-or-last;
      "Super+Right".action = focus-column-right-or-first;
      "Super+Down".action = focus-workspace-down;
      "Super+Up".action = focus-workspace-up;

      # "Print".action = screenshot;
      "Print".action.screenshot = [ ];
      "Mod+Print".action.screenshot-window = [ ];

      XF86AudioRaiseVolume = {
        action = spawn [
          "wpctl"
          "set-volume"
          "@DEFAULT_AUDIO_SINK@"
          "0.05+"
        ];
        allow-when-locked = true;
      };
      XF86AudioLowerVolume = {
        action = spawn [
          "wpctl"
          "set-volume"
          "@DEFAULT_AUDIO_SINK@"
          "0.05-"
        ];
        allow-when-locked = true;
      };
      XF86AudioMute = {
        action = spawn [
          "wpctl"
          "set-mute"
          "@DEFAULT_AUDIO_SINK@"
          "toggle"
        ];
        allow-when-locked = true;
      };
      XF86AudioMicMute = {
        action = spawn [
          "wpctl"
          "set-mute"
          "@DEFAULT_AUDIO_SOURCE@"
          "toggle"
        ];
        allow-when-locked = true;
      };
    };
  };
}
