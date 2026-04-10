{
  pkgs,
  lib,
  config,
  ...
}:
{
  imports = [
    ../shared/system/android.nix
    ../shared/system/containers.nix
    ../shared/system/firmware.nix
    ../shared/system/fonts.nix
    ../shared/system/hyperv.nix
    ../shared/system/lxc.nix
    ../shared/system/nix-credentials.nix
    ../shared/system/settings.nix
    ./hardware-configuration.nix
    ./services/default.nix
    ./settings.nix
    ./shadowsocks.nix
    ./users.nix
    ./wireguard.nix
    ./tailscale.nix
  ];

  security = {
    sudo = {
      wheelNeedsPassword = false;
      execWheelOnly = true;
    };
  };

  programs = {
    gnupg.dirmngr.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      enableExtraSocket = true;
      pinentryPackage = pkgs.pinentry-curses;
    };
  };
  virtualisation.oci-containers.containers.byparr = {
    image = "ghcr.io/thephaseless/byparr:latest";
    autoStart = true;
    ports = [
      "172.16.31.1:8191:8191"
    ];
    environment = {
      HOST = "172.16.31.1";
      PORT = "8191";
    };
  };
  nixpkgs.config.permittedInsecurePackages = [
    "mbedtls-2.28.10"
  ];

  environment.shells = builtins.attrValues { inherit (pkgs) zsh bash fish; };

  nixos.locale = {
    enable = true;
    timeZone = "Europe/Berlin";
    extraLocaleSettings = { };
  };

  services.avahi.enable = lib.mkForce false;
  services.displayManager.gdm.autoSuspend = false;

  system.stateVersion = config.system.nixos.release;
}
