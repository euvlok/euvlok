{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./fonts.nix
    ./input.nix
    ./power.nix
  ];

  nixos.plasma.enable = true;

  environment.plasma6.excludePackages = builtins.attrValues {
    inherit (pkgs.kdePackages) discover;
    inherit (pkgs) orca;
  };

  users.defaultUserShell = pkgs.zsh;
  programs = {
    nano.enable = true;
    nano.syntaxHighlight = true;
    zsh.enable = true;
    dconf.enable = true;
    steam.enable = true;
  };

  networking = {
    hostName = "nixos";
    networkmanager.plugins = builtins.attrValues { inherit (pkgs) networkmanager-openvpn; };
    networkmanager.wifi.powersave = true;
  };

  services.mullvad-vpn.enable = true;
  time.timeZone = "Asia/Ho_Chi_Minh";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console.font = "Lat2-Terminus16";
  console.keyMap = "us";

  # Configure keymap in X11
  services.xserver.xkb.layout = "us";
  services.xserver.xkb.options = "eurosign:e";

  users.users = {
    nanachi = {
      isNormalUser = true;
      extraGroups = [
        "networkmanager"
        "wheel"
        "docker"
        "libvirtd"
      ];
    };
  };

  # Virt-manager
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  # Docker
  virtualisation.docker.rootless.enable = true;
  virtualisation.docker.rootless.setSocketVariable = true;

  services.flatpak.enable = true;
  services.earlyoom.enable = true;

  # Set default editor
  environment.variables = {
    EDITOR = "nvim";
  };

  # https://wiki.nixos.org/wiki/FAQ#When_do_I_update_stateVersion
  system.stateVersion = "25.05";
}
