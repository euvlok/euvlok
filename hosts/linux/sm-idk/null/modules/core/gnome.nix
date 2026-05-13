{ lib, pkgs, ... }:
{
  services = {
    gnome = {
      glib-networking.enable = true;
      gnome-browser-connector.enable = true;
      # Disable gnome-keyring to use KeePassXC as unified secret service
      gnome-keyring.enable = lib.mkForce false;
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
    };

    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;

    gvfs.enable = true;
  };

  environment = {
    systemPackages = builtins.attrValues {
      inherit (pkgs)
        apostrophe # Markdown Editor
        gnome-obfuscate # Censor Private Info
        loupe # Image Viewer
        mousai # Shazam-like
        ;
      inherit (pkgs.gnomeExtensions) appindicator clipboard-indicator;
    };
    gnome.excludePackages = builtins.attrValues {
      inherit (pkgs)
        # baobab
        decibels
        epiphany
        gnome-text-editor
        gnome-calculator
        gnome-calendar
        gnome-characters
        gnome-clocks
        gnome-console
        gnome-contacts
        gnome-font-viewer
        # gnome-logs
        gnome-maps
        gnome-music
        gnome-system-monitor
        gnome-weather
        loupe
        simple-scan
        snapshot
        geary
        totem
        yelp
        ;
    };
  };
}
