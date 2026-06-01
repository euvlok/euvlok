{
  lib,
  pkgs,
  config,
  ...
}:
{
  imports = [
    ../shared/system/android.nix
    ../shared/system/containers.nix
    ../shared/system/fh.nix
    ../shared/system/firmware.nix
    ../shared/system/hyperv.nix
    ../shared/system/lxc.nix
    ../shared/system/desktop.nix
    ../shared/system/nix-credentials.nix
    ../shared/system/pam-security.nix
    ../shared/system/workstation.nix
    ../shared/system/settings.nix
    ../shared/system/fonts.nix
    ../shared/system/ollama.nix
    ./hardware-configuration.nix
    ./networking.nix
    ./overlays.nix
    ./samba.nix
    ./settings.nix
    ./users.nix
  ];

  hardware = {
    gpgSmartcards.enable = true;
    keyboard.qmk.enable = true;
    bluetooth = {
      settings.General = {
        ControllerMode = "bredr";
        AutoEnable = true;
        Experimental = true;
      };
    };
    opentabletdriver = {
      enable = true;
      package = pkgs.unstable.opentabletdriver;
      daemon.enable = true;
    };
    i2c.enable = true;
  };

  services = {
    displayManager.gdm.enable = lib.modules.mkForce false;
    displayManager.cosmic-greeter.enable = lib.modules.mkForce false;
    hardware.openrgb = {
      enable = true;
      motherboard = "amd";
      package = pkgs.unstable.openrgb-with-all-plugins;
    };
    hardware.bolt.enable = true;
    xserver = {
      enable = true;
      xkb.layout = "us";
      xkb.model = "evdev";
    };
    udev = {
      packages = builtins.attrValues {
        inherit (pkgs)
          libwacom
          via # qmk/via
          yubikey-personalization
          ;
        inherit (pkgs.unstable) opentabletdriver;
      };
      extraRules = ''
        # XP-Pen CT1060
        SUBSYSTEM=="hidraw", ATTRS{idVendor}=="28bd", ATTRS{idProduct}=="0932", MODE="0644"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="28bd", ATTRS{idProduct}=="0932", MODE="0644"
        SUBSYSTEM=="hidraw", ATTRS{idVendor}=="28bd", ATTRS{idProduct}=="5201", MODE="0644"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="28bd", ATTRS{idProduct}=="5201", MODE="0644"
        SUBSYSTEM=="input", ATTRS{idVendor}=="28bd", ATTRS{idProduct}=="5201", ENV{LIBINPUT_IGNORE_DEVICE}="1"

        # Wacom PTH-460
        KERNEL=="hidraw*", ATTRS{idVendor}=="056a", ATTRS{idProduct}=="03dc", MODE="0777", TAG+="uaccess", TAG+="udev-acl"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="056a", ATTRS{idProduct}=="03dc", MODE="0777", TAG+="uaccess", TAG+="udev-acl"
      '';
    };
    printing = {
      enable = true;
      drivers = builtins.attrValues {
        inherit (pkgs)
          cups-browsed
          cups-filters
          gutenprint
          gutenprintBin
          ;
      };
      browsing = true;
    };
    avahi = {
      enable = true;
      publish = {
        enable = true;
        userServices = true;
      };
      nssmdns4 = true;
      openFirewall = true;
    };
    lvm.boot.thin.enable = true;
    pcscd.enable = true;
    ratbagd.enable = true;
    xserver.wacom.enable = true;
  };
  programs.zsh.enable = true;

  nixpkgs.config.permittedInsecurePackages = [
    "electron-39.8.10"
  ];

  security.polkit.enable = true;

  programs = {
    ccache = {
      enable = true;
      packageNames = [
        "ansel"
        "gmic"
        "libreoffice"
        "mlt"
        "obs-studio"
        "octave"
        "onnxruntime"
        "opencv"
        "spectacle"
        "whisper-cpp"
      ];
    };
    gnupg.dirmngr.enable = true;
    gnupg.agent = {
      enable = true;
      enableBrowserSocket = true;
      enableExtraSocket = true;
    };
    android-development = {
      enable = true;
      users = [ "${config.users.users.ashuramaru.name}" ];
      waydroid.enable = true;
    };
    appimage = {
      enable = true;
      binfmt = true;
    };
    gphoto2.enable = true;
  };

  environment = {
    systemPackages = builtins.attrValues {
      inherit (pkgs)
        # yubico
        yubioath-flutter

        apfsprogs
        ccache
        fcitx5-gtk
        gpgme
        ;
      inherit (pkgs.unstable)
        cargo
        rust-analyzer
        rustc
        rustfmt
        ;
      inherit (pkgs.unstable.kdePackages)
        bluedevil
        ;
      inherit (pkgs.unstable)
        openrgb-with-all-plugins
        ;
    };
  };

  nix.settings.extra-sandbox-paths = [ config.programs.ccache.cacheDir ];

  system.stateVersion = config.system.nixos.release;
}
