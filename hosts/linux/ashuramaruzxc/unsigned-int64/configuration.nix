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

  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";

  services.avahi.enable = lib.mkForce false;
  services.displayManager.gdm.autoSuspend = false;

  sops.secrets.gh_token = {
    mode = "0440";
    group = "users";
  };
  sops.secrets.netrc_creds = {
    mode = "0440";
    group = "users";
  };

  nix.extraOptions = ''
    !include ${config.sops.secrets.gh_token.path}
  '';
  nix.settings = {
    netrc-file = config.sops.secrets.netrc_creds.path;
  };
  nix.gc.automatic = true;
  nix.gc.options = "--delete-older-than 14d";

  system.stateVersion = config.system.nixos.release;
}
