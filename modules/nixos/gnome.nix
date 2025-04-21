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
      pulseaudio.enable = false;
      udev.packages = builtins.attrValues { inherit (pkgs) gnome-settings-daemon; };
      xserver = {
        enable = true;
        displayManager.gdm.enable = true;
        desktopManager.gnome.enable = true;
      };
    };
    nixpkgs.overlays = lib.optionals ((lib.toInt (lib.versions.major pkgs.mutter.version)) < 48) [
      # GNOME 47: triple-buffering-v4-47
      (_: prev: {
        gnome = prev.gnome.overrideScope (
          _: gnomePrev: {
            mutter = gnomePrev.mutter.overrideAttrs (_: {
              src = pkgs.fetchFromGitLab {
                domain = "gitlab.gnome.org";
                owner = "vanvugt";
                repo = "mutter";
                # Tag: triple-buffering-v4-47
                rev = "4a884e571ea044e8078abc826cc1b1abd55c936c";
                hash = "sha256-6n5HSbocU8QDwuhBvhRuvkUE4NflUiUKE0QQ5DJEzwI=";
              };
            });
          }
        );
      })
    ];
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
        ++ lib.optionalAttrs config.catppuccin.enable {
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
          gnome-builder
          gnome-console
          gnome-maps
          gnome-music
          gnome-tour
          gnome-weather
          ;
      };
    };
  };
}
