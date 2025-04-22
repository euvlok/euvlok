{
  inputs,
  config,
  pkgs,
  ...
}:
{
  imports = [
    ../shared/android.nix
    ../shared/containers.nix
    ../shared/firmware.nix
    ../shared/fonts.nix
    ../shared/hyperv.nix
    ../shared/lxc.nix
    ../shared/plasma.nix
    ../shared/settings.nix
    ./hardware-configuration.nix
    ./networking.nix
    ./samba.nix
    ./users.nix
    inputs.sops-nix.nixosModules.sops
    {
      sops = {
        age.keyFile = "/var/lib/sops/age/keys.txt";
        defaultSopsFile = ../../../../secrets/ashuramaruzxc_unsigned-int32.yaml;
        secrets.gh_token = { };
        secrets.netrc_creds = { };
      };
    }
  ];

  environment.shells = builtins.attrValues { inherit (pkgs) zsh bash fish; };
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
  };

  services = {
    hardware.openrgb = {
      enable = true;
      motherboard = "amd";
    };
    hardware.bolt.enable = true;
    xserver = {
      enable = true;
      xkb.layout = "us";
      xkb.model = "evdev";
    };
    udev = {
      packages = builtins.attrValues {
        inherit (pkgs.gnome2) GConf;
        inherit (pkgs)
          libwacom
          yubikey-personalization
          gnome-settings-daemon
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
      drivers = builtins.attrValues { inherit (pkgs) gutenprintBin; };
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
    xserver.wacom.enable = true;
  };

  programs = {
    anime-game-launcher.enable = true;
    honkers-railway-launcher.enable = true;
    zsh.enable = true;
  };

  security = {
    wrappers = {
      doas = {
        setuid = true;
        owner = "root";
        group = "root";
        source = "${pkgs.doas}/bin/doas";
      };
    };
    sudo = {
      enable = true;
      wheelNeedsPassword = true;
    };
    doas = {
      enable = true;
      wheelNeedsPassword = true;
    };
    polkit = {
      enable = true;
      adminIdentities = [ "unix-group:wheel" ];
    };
    pam = {
      services = {
        login = {
          sshAgentAuth = true;
          u2fAuth = true;
          enableGnomeKeyring = true;
          enableKwallet = true;
        };
        su = {
          sshAgentAuth = true;
          u2fAuth = true;
        };
        sudo = {
          sshAgentAuth = true;
          u2fAuth = true;
        };
        sshd = {
          sshAgentAuth = true;
          u2fAuth = true;
          enableGnomeKeyring = true;
          enableKwallet = true;
          googleOsLoginAuthentication = true;
          googleOsLoginAccountVerification = true;
          googleAuthenticator.enable = true;
        };
      };
      u2f = {
        enable = true;
        settings = {
          cue = true;
        };
        control = "required";
      };
    };
  };

  programs = {
    gnupg.dirmngr.enable = true;
    gnupg.agent = {
      enable = true;
      enableBrowserSocket = true;
      enableExtraSocket = true;
    };
    android-development = {
      enable = true;
      users = [ "ashuramaru" ];
      waydroid.enable = true;
    };
    appimage = {
      enable = true;
      binfmt = true;
    };
    gphoto2.enable = if config.services.gvfs.enable == true then true else false;
  };

  environment = {
    systemPackages = builtins.attrValues {
      inherit (pkgs)
        # yubico
        apfsprogs
        fcitx5-gtk
        gpgme
        yubioath-flutter
        ;
      inherit (pkgs.xorg) xhost;
    };
  };

  time.timeZone = "Europe/Warsaw";

  i18n = {
    defaultLocale = "en_US.utf8";
    supportedLocales = [ "all" ];
    inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5 = {
        plasma6Support = true;
        waylandFrontend = true;
        addons = builtins.attrValues {
          inherit (pkgs) fcitx5-anthy fcitx5-gtk;
          inherit (pkgs) fcitx5-mozc;
        };
      };
    };
  };
  nix.settings = {
    access-tokens = config.sops.secrets.gh_token.path;
    netrc-file = config.sops.secrets.netrc_creds.path;
  };
  nix.gc.automatic = true;
  nix.gc.options = "--delete-older-than 14d";

  system.stateVersion = "24.11";
}
