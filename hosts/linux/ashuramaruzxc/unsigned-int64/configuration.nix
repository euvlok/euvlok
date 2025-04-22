{ pkgs, config, ... }:
{
  imports = [
    ../shared/firmware.nix
    ../shared/fonts.nix
    ../shared/plasma.nix
    ../shared/settings.nix

    ./hardware-configuration.nix
    ./users.nix
  ];

  security = {
    sudo = {
      wheelNeedsPassword = false;
      execWheelOnly = true;
    };
  };

  programs = {
    gnupg.dirmngr.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      enableExtraSocket = true;
      pinentryPackage = pkgs.pinentry-curses;
    };
  };

  environment.shells = builtins.attrValues { inherit (pkgs) zsh bash fish; };

  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";

  system.stateVersion = config.system.nixos.release;
}
