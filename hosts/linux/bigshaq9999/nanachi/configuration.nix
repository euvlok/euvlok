{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./fonts.nix
    ./input.nix
    ./power.nix
  ];

  environment.plasma6.excludePackages = [
    pkgs.kdePackages.discover
    pkgs.orca
  ];

  users.defaultUserShell = pkgs.zsh;
  users.users.nanachi = {
    isNormalUser = true;
    extraGroups = [
      "networkmanager"
      "wheel"
      "libvirtd"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKSS01C9Um/08HZJH8CCTdUvkJK8RUmZ4QD91V5KAFfd"
    ];
  };

  programs = {
    nano = {
      enable = true;
      syntaxHighlight = true;
    };
    zsh.enable = true;
    dconf.enable = true;
    # steam.enable = true;
    virt-manager.enable = true;
  };

  networking = {
    hostName = "nixos";
    networkmanager.plugins = [ pkgs.networkmanager-openvpn ];
  };

  services.openssh.enable = true;
  services.tailscale.enable = true;

  euvlok.nixos.locale = {
    enable = true;
    timeZone = "Asia/Ho_Chi_Minh";
  };
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };
  services.xserver.xkb = {
    layout = "us";
    options = "eurosign:e";
  };

  services = {
    # mullvad-vpn.enable = true;
    flatpak.enable = true;
    earlyoom.enable = true;
  };

  virtualisation = {
    libvirtd.enable = true;
    docker.rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  # Preserve the installed system's compatibility defaults
  system.stateVersion = "25.05";
}
