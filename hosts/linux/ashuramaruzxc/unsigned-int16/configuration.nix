{
  pkgs,
  lib,
  config,
  ...
}:
{
  imports = [
    ../../../hm/ashuramaruzxc/fonts.nix
    ../shared/settings.nix
    ./hardware-configuration.nix
    ./settings.nix
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
      enableExtraSocket = true;
      pinentryPackage = pkgs.pinentry-curses;
    };
  };
  programs.zsh.enable = true;

  time.timeZone = "Europe/Warsaw";
  i18n.defaultLocale = "en_US.UTF-8";

  services.avahi.enable = lib.mkForce false;
  services.xserver.displayManager.gdm.autoSuspend = false;

  # sops.secrets.gh_token = { };
  # sops.secrets.netrc_creds = { };

  # nix.settings = {
  #   access-tokens = config.sops.secrets.gh_token.path;
  #   netrc-file = config.sops.secrets.netrc_creds.path;
  # };
  nix.gc.automatic = true;
  nix.gc.options = "--delete-older-than 14d";

  system.stateVersion = config.system.nixos.release;
}
