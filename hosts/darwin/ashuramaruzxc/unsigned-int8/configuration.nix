{ containerPackage }:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../../../linux/ashuramaruzxc/shared/system/fonts.nix
  ];
  system.primaryUser = "ashuramaru";

  nixpkgs.hostPlatform = "aarch64-darwin";

  security.pam.services.sudo_local.touchIdAuth = true;
  services.openssh.enable = true;
  services.tailscale.enable = true;
  launchd.daemons.tailscaled.serviceConfig.KeepAlive = true;
  environment.etc."resolver/ts.net".enable = false;

  sops.secrets.tailscale_auth = { };

  # nix-darwin has no authKeyFile option. Retry until SOPS and tailscaled are ready.
  launchd.daemons.tailscale-autoconnect = {
    path = [ pkgs.jq ];
    script = ''
      set -euo pipefail

      tailscale() {
        ${lib.meta.getExe' config.services.tailscale.package "tailscale"} \
          --socket=/var/run/tailscaled.socket "$@"
      }

      state="$(tailscale status --json | jq -er '.BackendState')"
      case "$state" in
        NeedsLogin)
          test -r ${lib.strings.escapeShellArg config.sops.secrets.tailscale_auth.path}
          tailscale up \
            --auth-key=${lib.strings.escapeShellArg "file:${config.sops.secrets.tailscale_auth.path}"} \
            --advertise-tags=tag:unsigned-int8 \
            --timeout=30s
          ;;
        Stopped)
          tailscale up --timeout=30s
          ;;
        Running) ;;
        *)
          echo "Waiting for Tailscale to be ready (state: $state)"
          exit 1
          ;;
      esac
    '';
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive.SuccessfulExit = false;
      ThrottleInterval = 30;
      StandardOutPath = "/var/log/tailscale-autoconnect.log";
      StandardErrorPath = "/var/log/tailscale-autoconnect.log";
    };
  };

  networking = {
    computerName = "Marie's Macbook Pro 16 M4 Max unsigned-int8";
    hostName = "unsigned-int8";
    localHostName = "unsigned-int8";
    knownNetworkServices = [
      "Ethernet"
      "Thunderbolt Bridge"
      "Wi-Fi"
    ];
  };

  users.users =
    let
      ssh-keys = import ../../../keys/ashuramaru.nix;
    in
    {
      ashuramaru = {
        home = "/Users/ashuramaru";
        description = "Maria Głowata";
        openssh.authorizedKeys.keys = ssh-keys;
        shell = pkgs.zsh;
      };
    };

  programs = {
    gnupg.agent.enable = true;
    gnupg.agent.enableSSHSupport = false;
    nix-index.enable = true;
    pared.features.mailSummaries = true;
    # Environment
  };

  nixpkgs.config.permittedInsecurePackages = [
    "electron-39.8.10"
  ];

  environment.systemPackages = lib.attrsets.attrValues {
    container = containerPackage;

    inherit (pkgs.unstable)
      # Literally should be bultin but apple being apple
      # Utils
      wireguard-tools
      smartmontools
      # Virtualization
      podman
      podman-compose
      vfkit
      # Android
      android-tools
      scrcpy
      # fine lol
      gnupg
      libfido2
      pinentry_mac
      ;

    inherit (pkgs.eupkgs) soundsource;
  };
  # sops.secrets.gh_token = { };
  # sops.secrets.netrc_creds = { };

  # Determinate owns netrc-file. Additional credentials must be outside the
  # Nix store and registered with Determinate Nixd instead:
  # determinateNix.determinateNixd.authentication.additionalNetrcSources = [
  #   config.sops.secrets.netrc_creds.path
  # ];

  # Use Determinate's native macOS Virtualization.framework Linux builder
  # instead of nix-darwin's NixOS VM builder.
  determinateNix.determinateNixd.builder.state = "enabled";
}
