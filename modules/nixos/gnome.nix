{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.nixos.gnome.enable = lib.mkEnableOption "GNOME";

  config = lib.mkIf config.nixOS.gnome.enable {
    services.xserver = {
      enable = true;
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
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
    services.udev.packages = builtins.attrValues { inherit (pkgs) gnome-settings-daemon; };
    services.pulseaudio.enable = false;
    environment = {
      systemPackages = builtins.attrValues {
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
