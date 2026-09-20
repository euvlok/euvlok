{
  pkgs,
  lib,
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
      powerOnBoot = lib.modules.mkForce true;
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

  nixpkgs.config.permittedInsecurePackages = [
    "electron-39.8.10"
  ];

  nixpkgs.overlays = [
    (_: previous: {
      mullvad-vpn = previous.mullvad-vpn.overrideAttrs {
        versionCheckProgram = "${builtins.placeholder "out"}/bin/mullvad";
        versionCheckProgramArg = "--version";
      };
    })
  ];

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

  # This must describe the installation, not follow the current nixpkgs
  # release. Keep it aligned with this host's Home Manager state version.
  system.stateVersion = "26.05";
}
