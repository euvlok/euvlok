{
  pkgs,
  lib,
  config,
  ...
}:
{
  home.pointerCursor = {
    enable = true;
    name = "phinger-cursors-light";
    package = pkgs.phinger-cursors;
    size = 64;
    gtk.enable = true;
    x11 = {
      enable = true;
      defaultCursor = "phinger-cursors-light";
    };
  };

  gtk = {
    enable = true;
    cursorTheme = {
      name = "Catppuccin-Frappe-Dark-Cursors";
      package = pkgs.catppuccin-cursors.frappeDark;
    };
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
    catppuccin = {
      enable = true;
      flavor = "frappe";
      accent = "rosewater";
      size = "standard";
      tweaks = [ "normal" ];
    };
  };

  services.kanshi = {
    enable = true;
    settings = [
      {
        profile = {
          name = "docked";
          outputs = [
            {
              criteria = "eDP-1";
              status = "disable";
            }
            {
              criteria = "HDMI-A-1";
              status = "enable";
              mode = "1920x1080@60.000";
            }
          ];
        };
      }
      {
        profile = {
          name = "undocked";
          outputs = [
            {
              criteria = "eDP-1";
              status = "enable";
            }
          ];
        };
      }
    ];
  };

  programs.niri.settings = {
    input = {
      touchpad = {
        tap = true;
        natural-scroll = false;
        accel-profile = "flat";
        accel-speed = 0.2;
        scroll-factor = 0.2;
      };
    };
    layout = {
      gaps = 10;
      preset-column-widths = [
        { proportion = 1. / 3.; }
        { proportion = 1. / 2.; }
        { proportion = 2. / 3.; }
      ];
      default-column-width = {
        proportion = 0.9;
      };
      focus-ring = {
        width = 4;
        active.color = "#7fc8ff";
        inactive.color = "#505050";
      };
      border = {
        enable = false;
      };
      shadow = {
        enable = true;
      };
    };
    spawn-at-startup = [
      { command = [ (lib.getExe pkgs.waybar) ]; }
      {
        command = [
          (lib.getExe' pkgs.wl-clipboard "wl-paste")
          "--watch"
          "cliphist"
          "store"
        ];
      }
      { command = [ (lib.getExe pkgs.xwayland-satellite) ]; }
      {
        command = [
          (lib.getExe pkgs.swaylock)
          "-w"
          "timeout"
          "601"
          "'niri msg action power-off-monitors'"
          "timeout"
          "600"
          "'swaylock -f'"
          "before-sleep"
          "'swaylock -f'"
        ];
      }
    ];
    prefer-no-csd = true;
    screenshot-path = "~/Pictures/Screenshots/Screenshot_%Y%m%d_%H%M%S.png";
  };

  programs.niri.settings.binds =
    with config.lib.niri.actions;
    let
      sh = spawn "sh" "-c";
    in
    {
      "Mod+Shift+Slash".action = show-hotkey-overlay;
      "Mod+T".action = spawn "kitty";
      "Mod+D".action = spawn "fuzzel";
      "Super+Alt+L".action =
        spawn "swaylock" "-i"
          "./Downloads/Media/wallpapers/scaled_16-9-IMG_7584.png";

      "Mod+Ctrl+F".action = expand-column-to-available-width;

      "Mod+Shift+P".action = power-off-monitors;
      "Mod+Apostrophe".action = spawn "wlogout";

      "Mod+Slash".action = sh "cliphist list | fuzzel --dmenu | cliphist decode | wl-copy";
    };
}
