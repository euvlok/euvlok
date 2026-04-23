{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (import ../../lib/catppuccin.nix) mkCatppuccinGtk;
in
{
  #! temp remove gnome from nixos-unstable
  # disabledModules = [ "services/desktop-managers/gnome.nix" ];

  # imports = [
  #   ("${inputs.nixpkgs-unstable-small.outPath}/nixos/modules/services/desktop-managers/gnome.nix")
  # ];

  options.nixos.gnome.enable = lib.mkEnableOption "GNOME";

  config = lib.mkIf config.nixos.gnome.enable {
    nixos.gui.enable = lib.mkDefault true;

    services = {
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
      gnome = {
        glib-networking.enable = true;
        gnome-browser-connector.enable = true;
        gnome-online-accounts.enable = true;
        gnome-remote-desktop.enable = true;
        sushi.enable = true;
      };
    };

    environment = {
      systemPackages =
        builtins.attrValues {
          inherit (pkgs.unstable)
            apostrophe # Markdown Editor
            decibels # Audio Player
            gnome-obfuscate # Censor Private Info
            loupe # Image Viewer
            mousai # Shazam-like
            resources # Task Manager
            textpieces
            ;
          inherit (pkgs.unstable.gnomeExtensions) appindicator clipboard-indicator;
        }
        ++ lib.optionals config.catppuccin.enable [
          (mkCatppuccinGtk {
            inherit pkgs config;
            tweaks = [ "normal" ];
          })
        ];

      gnome.excludePackages = builtins.attrValues {
        inherit (pkgs.unstable)
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
