{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
# GNOME Stuff
{
  services.gnome = {
    at-spi2-core.enable = true;
    core-developer-tools.enable = true;
    core-utilities.enable = true;
    localsearch.enable = true;
    tinysparql.enable = true;
  };

  services.xserver.displayManager.gdm.autoSuspend = true;

  environment.systemPackages = builtins.attrValues {
    inherit (pkgs)
      adw-gtk3
      adwaita-icon-theme
      adwaita-qt
      adwaita-qt6
      adwsteamgtk
      gnome-boxes
      gnome-themes-extra
      gnome-tweaks
      ;

    inherit (pkgs.gnomeExtensions)
      appindicator
      arcmenu
      blur-my-shell
      clipboard-history
      dash-to-dock
      dual-monitor-toggle
      gsconnect
      kimpanel
      pop-shell
      rounded-corners
      smart-auto-move
      ;
  };
}
// {
  services = {
    dbus.packages = builtins.attrValues { inherit (pkgs) gcr; };
    desktopManager.plasma6.enable = true;
    displayManager.defaultSession = "plasma";
    libinput = {
      mouse.accelProfile = "flat";
      mouse.accelSpeed = "0";
    };
    sysprof.enable = true;
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    xdgOpenUsePortal = true;
  };

  qt.enable = true;
  qt.platformTheme = "kde";

  programs = {
    calls.enable = true;
    gnome-terminal.enable = true;
    gnupg.agent.pinentryPackage = pkgs.pinentry-qt;
    kdeconnect.enable = true;
    ssh.askPassword = lib.mkForce (lib.getExe pkgs.kdePackages.ksshaskpass);
  };

  environment.systemPackages = builtins.attrValues {
    inherit (pkgs)
      capitaine-cursors
      catppuccin-kde
      catppuccin-kvantum
      ;

    inherit (inputs.lightly.packages.${config.nixpkgs.hostPlatform.system})
      darkly-qt5
      darkly-qt6
      ;

    inherit (pkgs)
      gparted
      gradience
      pop-launcher
      sysprof
      ;

    inherit (pkgs.kdePackages)
      breeze
      breeze-gtk
      breeze-icons
      ;

    inherit (pkgs.kdePackages)
      ark
      dolphin
      filelight
      kclock
      konsole
      merkuro # mail client

      # Kio
      dolphin-plugins
      kio-admin
      kio-extras
      kio-extras-kf5
      kio-fuse
      kio-gdrive
      kio-zeroconf

      # For some reason it's not enabled by default
      accounts-qt
      calendarsupport
      kaccounts-integration
      kaccounts-providers
      kauth
      qtspeech
      signon-kwallet-extension
      signond

      # Formats
      kdegraphics-thumbnailers # blender etc
      kdesdk-thumbnailers # test
      kimageformats # gimp
      qtimageformats # webp etc
      qtsvg # svg

      # Misc
      discover
      flatpak-kcm
      kcmutils
      packagekit-qt
      ;
  };
}
