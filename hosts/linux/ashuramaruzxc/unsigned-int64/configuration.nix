{ pkgs, config, ... }:
{
  imports = [
    ../shared/android.nix
    ../shared/containers.nix
    ../shared/firmware.nix
    ../shared/fonts.nix
    ../shared/hyperv.nix
    ../shared/lxc.nix
    ../shared/settings.nix

    ./services/default.nix

    ./shadowsocks.nix
    ./tailscale.nix
    ./wireguard.nix

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
