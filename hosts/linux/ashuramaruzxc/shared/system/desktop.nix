{
  pkgs,
  lib,
  ...
}:
# GNOME Stuff
{
  services = {
    gnome = {
      at-spi2-core.enable = true;
      core-developer-tools.enable = true;
      core-utilities.enable = true;
      localsearch.enable = true;
      tinysparql.enable = true;
      gnome-keyring.enable = true;
    };
    libinput = {
      mouse.accelProfile = "flat";
      mouse.accelSpeed = "0";
    };
  };

  environment.systemPackages = lib.attrsets.attrValues {
    inherit (pkgs.unstable)
      bitwarden-desktop
      gnome-boxes
      gnome-themes-extra
      gnome-tweaks
      gparted
      pop-launcher
      ;
    inherit (pkgs.unstable.kdePackages)
      krohnkite
      ;
    inherit (pkgs.unstable.gnomeExtensions)
      arcmenu
      auto-move-windows
      blur-my-shell
      dash-to-dock
      gsconnect
      kimpanel
      pop-shell
      rounded-corners
      smart-auto-move
      system-monitor
      user-themes
      ;
  };

  qt.enable = true;
  qt.platformTheme = "kde";

  programs.gnupg.agent.pinentryPackage = pkgs.pinentry-qt;
  programs.kdeconnect.enable = true;
  programs.ssh.askPassword = lib.modules.mkForce (lib.meta.getExe pkgs.seahorse);
}
