{
  pkgs,
  config,
  ...
}:
{
  imports = [
    ./docker.nix
    ./hardware-configuration.nix
    ./networking.nix
    ./settings.nix
    ./virtualization.nix
  ];
  programs.zsh.enable = true;
  environment.localBinInPath = true;
  environment.sessionVariables = rec {
    XDG_CACHE_HOME = "\${HOME}/.cache";
    XDG_CONFIG_HOME = "\${HOME}/.config";
    XDG_DATA_HOME = "\${HOME}/.local/share";
    XDG_DATA_DIRS = [ "${XDG_DATA_HOME}/.icons" ];
  };

  sops.secrets.reisen.neededForUsers = true;
  users.mutableUsers = false;
  users.users.reisen = {
    isNormalUser = true;
    description = "Reisen Inaba";
    extraGroups = [
      "adbusers"
      "audio"
      "cdrom"
      "network"
      "video"
      "wheel"
    ];
    shell = pkgs.zsh;
    hashedPasswordFile = config.sops.secrets.reisen.path;
    openssh.authorizedKeys.keys = [ ]; # ! @2husecondary don't forget to add your public key
  };

  time.timeZone = "Asia/Baku";
  # Keyboard layout
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };

  programs = {
    gnupg.dirmngr.enable = true;
    gnupg.agent = {
      enable = true;
      enableBrowserSocket = true;
      enableExtraSocket = true;
    };
    appimage = {
      enable = true;
      binfmt = true;
    };
    gphoto2.enable = true;
  };

  fonts.fontconfig.defaultFonts = {
    monospace = [ "Monaspice Kr Nerd Font" ];
    sansSerif = [ "Noto Nerd Font" ];
    serif = [ "Noto Nerd Font" ];
    emoji = [ "Twitter Color Emoji" ];
  };
  fonts.packages = builtins.attrValues {
    Ubuntu = pkgs.nerd-fonts.ubuntu;
    UbuntuMono = pkgs.nerd-fonts.ubuntu-mono;
    UbuntuSans = pkgs.nerd-fonts.ubuntu-sans;
    FiraCode = pkgs.nerd-fonts.fira-code;
    Monaspace = pkgs.nerd-fonts.monaspace;
    Noto = pkgs.nerd-fonts.noto;

    inherit (pkgs)
      noto-fonts-cjk-sans
      noto-fonts-emoji
      twemoji-color-font
      ;
  };

  nix.gc.automatic = true;
  nix.gc.options = "--delete-older-than 14d";

  system.stateVersion = config.system.nixos.release;
}
