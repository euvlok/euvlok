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
  services.gnome.gnome-keyring.enable = true;
  nixpkgs.overlays = [
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

  environment.systemPackages = builtins.attrValues {
    inherit (pkgs)
      gnome-boxes
      gnome-themes-extra
      gnome-tweaks
      gparted
      pop-launcher
      ;

    inherit (pkgs.gnomeExtensions)
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
