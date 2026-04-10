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
    ../shared/system/settings.nix
    ./hardware-configuration.nix
    ./settings.nix
    ./users.nix
  ];

  environment.localBinInPath = true;
  environment.sessionVariables = {
    XDG_DATA_HOME = "\${HOME}/.local/share";
    XDG_CACHE_HOME = "\${HOME}/.cache";
    XDG_CONFIG_HOME = "\${HOME}/.config";
    XDG_DATA_DIRS = [ "\${HOME}/.local/share/.icons" ];
  };

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

  nixos.locale = {
    enable = true;
    timeZone = "Europe/Warsaw";
    extraLocaleSettings = {
      LC_MESSAGES = "en_US.UTF-8";
      LC_MEASUREMENT = "pl_PL.UTF-8";
      LC_MONETARY = "pl_PL.UTF-8";
      LC_TIME = "pl_PL.UTF-8";
      LC_PAPER = "pl_PL.UTF-8";
      LC_ADDRESS = "pl_PL.UTF-8";
      LC_TELEPHONE = "pl_PL.UTF-8";
      LC_NUMERIC = "pl_PL.UTF-8";
    };
  };
  i18n = {
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "pl_PL.UTF-8/UTF-8"
      "all"
    ];
    inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5 = {
        plasma6Support = true;
        waylandFrontend = true;
        addons = builtins.attrValues {
          inherit (pkgs) fcitx5-gtk fcitx5-mozc;
        };
      };
    };
  };
  fonts.fontconfig.defaultFonts = {
    monospace = [ "Hack Nerd Font Mono" ];
    sansSerif = [ "Noto Nerd Font" ];
    serif = [ "Noto Nerd Font" ];
    emoji = [ "Twitter Color Emoji" ];
  };
  system.stateVersion = config.system.nixos.release;
}
