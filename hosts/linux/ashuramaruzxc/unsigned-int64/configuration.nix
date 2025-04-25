{
  lib,
  pkgs,
  config,
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
    ../shared/settings.nix

    ./services/default.nix
    ./settings.nix
    ./shadowsocks.nix
    # ./tailscale.nix
    ./wireguard.nix

    ./hardware-configuration.nix
    ./users.nix
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
  virtualisation.oci-containers.containers.FlareSolverr = {
    image = "ghcr.io/flaresolverr/flaresolverr:latest";
    autoStart = true;
    ports = [
      "172.16.31.1:8191:8191"
      "127.0.0.1:8191:8191"
    ];

    environment = {
      LOG_LEVEL = "info";
      LOG_HTML = "false";
      CAPTCHA_SOLVER = "hcaptcha-solver";
      TZ = "${config.time.timeZone}";
    };
  };
  environment.shells = builtins.attrValues { inherit (pkgs) zsh bash fish; };

  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";

  services.avahi.enable = lib.mkForce false;
  services.xserver.displayManager.gdm.autoSuspend = false;

  sops.secrets.gh_token = { };
  sops.secrets.netrc_creds = { };

  nix.settings = {
    access-tokens = config.sops.secrets.gh_token.path;
    netrc-file = config.sops.secrets.netrc_creds.path;
  };
  nix.gc.automatic = true;
  nix.gc.options = "--delete-older-than 14d";

  system.stateVersion = config.system.nixos.release;
}
