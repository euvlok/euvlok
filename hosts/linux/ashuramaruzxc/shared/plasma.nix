{
  inputs,
  config,
  pkgs,
  lib,
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
      ;

    inherit
      (inputs.nixpkgs-unstable.legacyPackages.${config.nixpkgs.hostPlatform.system}.gnomeExtensions)
      arcmenu
      blur-my-shell
      dash-to-dock
      dual-monitor-toggle
      gsconnect
      kimpanel
      pop-shell
      rounded-corners
      smart-auto-move
      system-monitor
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

  programs = {
    calls.enable = true;
    gnupg.agent.pinentryPackage = pkgs.pinentry-qt;
    kdeconnect.enable = true;
    ssh.startAgent = true;
    ssh.askPassword = lib.mkForce (lib.getExe pkgs.seahorse);
  };
}
