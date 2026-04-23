{
  pkgs,
  lib,
  config,
  ...
}:
{
  imports = [
    ../shared/system/containers.nix
    ../shared/system/fonts.nix
    ../shared/system/hyperv.nix
    ../shared/system/lxc.nix
    ../shared/system/desktop.nix
    ../shared/system/nix-credentials.nix
    ../shared/system/pam-security.nix
    ../shared/system/workstation.nix
    ../shared/system/settings.nix
    ./hardware-configuration.nix
    ./settings.nix
    ./users.nix
  ];

  hardware = {
    gpgSmartcards.enable = true;
    bluetooth = {
      powerOnBoot = lib.mkForce true;
      settings.General = {
        AutoEnable = true;
        Experimental = true;
      };
    };
  };

  services = {
    xserver = {
      enable = true;
      xkb.layout = "us";
      xkb.model = "evdev";
    };
    udev = {
      packages = builtins.attrValues {
        inherit (pkgs) yubikey-personalization;
      };
    };
    pcscd.enable = true;
  };

  programs.zsh.enable = true;

  programs = {
    gnupg.dirmngr.enable = true;
    gnupg.agent = {
      enable = true;
      enableExtraSocket = true;
    };
    appimage = {
      enable = true;
      binfmt = true;
    };
    gphoto2.enable = true;
  };

  environment = {
    systemPackages = builtins.attrValues {
      inherit (pkgs) fcitx5-gtk;
      inherit (pkgs.unstable.kdePackages) bluedevil;
    };
  };

  system.stateVersion = config.system.nixos.release;
}
