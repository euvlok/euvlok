{ pkgs, config, ... }:
{
  imports = [
    ../../../hm/ashuramaruzxc/fonts.nix
    ../shared/settings.nix
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
      settings.General = {
        ControllerMode = "bredr";
        AutoEnable = true;
        Experimental = true;
      };
    };
  };

  services = {
    udev = {
      packages = builtins.attrValues { inherit (pkgs) yubikey-personalization; };
    };
    printing = {
      enable = true;
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
  };

  programs.zsh.enable = true;

  security = {
    polkit.adminIdentities = [ "unix-group:wheel" ];
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
      # u2f = {
      # enable = true;
      # settings = {
      # cue = true;
      # };
      # control = "required";
      # };
    };
  };

  programs = {
    gnupg.dirmngr.enable = true;
    gnupg.agent = {
      enable = true;
      enableExtraSocket = true;
      pinentryPackage = pkgs.pinentry-curses;
    };
    appimage = {
      enable = true;
      binfmt = true;
    };
    dconf.enable = config.services.xserver.enable;
    gphoto2.enable = true;
    nix-index.enableBashIntegration = true;
    nix-index.enableZshIntegration = true;
  };

  time.timeZone = "Europe/Warsaw";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "pl_PL.UTF-8/UTF-8"
      "all"
    ];
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
  fonts.fontconfig.defaultFonts = {
    monospace = [ "Hack Nerd Font Mono" ];
    sansSerif = [ "Noto Nerd Font" ];
    serif = [ "Noto Nerd Font" ];
    emoji = [ "Twitter Color Emoji" ];
  };
  # sops.secrets.gh_token = { };
  # sops.secrets.netrc_creds = { };

  # nix.settings.access-tokens = config.sops.secrets.gh_token.path;
  # nix.settings.netrc-file = config.sops.secrets.netrc_creds.path;

  nix.gc.automatic = true;
  nix.gc.options = "--delete-older-than 14d";

  system.stateVersion = config.system.nixos.release;
}
