{
  inputs,
  config,
  pkgs,
  lib,
  pkgsUnstable,
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
  services.gnome.gnome-keyring.enable = true;

  environment.systemPackages = builtins.attrValues {
    inherit (pkgs)
      gnome-boxes
      gnome-themes-extra
      gnome-tweaks
      gparted
      pop-launcher
      polonium
      ;
    inherit (pkgsUnstable.kdePackages)
      krohnkite
      ;
    inherit (pkgsUnstable.gnomeExtensions)
      arcmenu
      auto-move-windows
      blur-my-shell
      dash-to-dock
      dual-monitor-toggle
      gsconnect
      kimpanel
      pop-shell
      rounded-corners
      smart-auto-move
      system-monitor
      user-themes
      ;
  };
}
// {
  services = {
    libinput = {
      mouse.accelProfile = "flat";
      mouse.accelSpeed = "0";
    };
  };

  qt.enable = true;
  qt.platformTheme = "kde";

  programs.gnupg.agent.pinentryPackage = pkgs.pinentry-qt;
  programs.kdeconnect.enable = true;
  programs.ssh.askPassword = lib.mkForce (lib.getExe pkgs.seahorse);

}
