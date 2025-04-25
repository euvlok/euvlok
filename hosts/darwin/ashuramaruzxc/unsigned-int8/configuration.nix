{
  inputs,
  pkgs,
  config,
  ...
}:
let
  add-24_05-packages = final: _: {
    nixpkgs-24_05 = import inputs.nixpkgs-ashuramaruzxc { inherit (final) system config; };
  };
  addUnstablePackages = final: _: {
    unstable = import inputs.nixpkgs-unstable { inherit (final) system config; };
  };
in
{
  nixpkgs.hostPlatform.system = "aarch64-darwin";

  security.pam.enableSudoTouchIdAuth = true;

  networking = {
    computerName = "Marie's Mac Mini M2 Pro unsigned-int8";
    hostName = "unsigned-int8";
    localHostName = "unsigned-int8";
    knownNetworkServices = [
      "Ethernet"
      "Thunderbolt Bridge"
      "Wi-Fi"
    ];
    dns = [
      "192.168.1.1"
      "172.16.31.1"
      "fd17:216b:31bc:1::1"
    ];
  };

  services.nix-daemon.enable = true;
  services.tailscale.enable = true;

  users.users = {
    ashuramaru = {
      home = "/Users/ashuramaru";
      shell = pkgs.zsh;
    };
    meanrin = {
      home = "/Users/meanrin";
      shell = pkgs.zsh;
    };
  };

  programs = {
    gnupg.agent.enable = true;
    gnupg.agent.enableSSHSupport = true;
    nix-index.enable = true;
  };

  # Environment
  environment.systemPackages = builtins.attrValues {
    inherit (pkgs)
      # Literally should be bultin but apple being apple
      soundsource
      # Utils
      wireguard-tools
      smartmontools

      # Virtualization
      vfkit
      podman
      podman-compose

      # Android
      android-tools
      scrcpy
      ;
  };

  nixpkgs.overlays = [
    add-24_05-packages
    addUnstablePackages
  ];
}
