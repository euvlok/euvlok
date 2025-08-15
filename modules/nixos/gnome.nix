{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.nixos.gnome.enable = lib.mkEnableOption "GNOME";

  config = lib.mkIf config.nixos.gnome.enable {
    services = {
      gnome = {
        glib-networking.enable = true;
        gnome-browser-connector.enable = true;
        gnome-keyring.enable = true;
        gnome-online-accounts.enable = true;
        gnome-remote-desktop.enable = true;
        gnome-settings-daemon.enable = true;
        sushi.enable = true;
      };
      dbus.packages = builtins.attrValues { inherit (pkgs) gcr; };
      udev.packages = builtins.attrValues {
        inherit (pkgs) gnome-settings-daemon;
        inherit (pkgs.gnome2) GConf;
      };
      xserver = {
        enable = true;
        displayManager.gdm.enable = true;
        desktopManager.gnome.enable = true;
      };
      gvfs.enable = true;
    };

    environment = {
      systemPackages =
        builtins.attrValues {
          inherit (pkgs)
            apostrophe # Markdown Editor
            decibels # Audio Player
            gnome-obfuscate # Censor Private Info
            loupe # Image Viewer
            mousai # Shazam-like
            resources # Task Manager
            textpieces
            ;
          inherit (pkgs.gnomeExtensions) appindicator clipboard-indicator;
        }
        ++ lib.optionalAttrs config.catppuccin.enable builtins.attrValues {
          catppuccin-gtk = pkgs.catppuccin-gtk.override {
            accents = [ config.catppuccin.accent ];
            size = "compact";
            tweaks = [ "normal" ];
            variant = config.catppuccin.flavor;
          };
        };
      gnome.excludePackages = builtins.attrValues {
        inherit (pkgs)
          epiphany # Browser
          evince # Docs
          geary # Email
          # gnome-builder
          gnome-console
          # gnome-maps
          gnome-music
          gnome-tour
          # gnome-weather
          ;
      };
    };
  };
}
