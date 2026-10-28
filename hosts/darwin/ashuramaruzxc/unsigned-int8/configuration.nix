{ containerPackage }:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  system.primary.user = "ashuramaru";

  imports = [
    ../../../../modules/darwin/host-services.nix
    (lib.modules.importApply ../../../../modules/darwin/fonts.nix {
      packages =
        (import ../../../linux/ashuramaruzxc/shared/system/fonts.nix { inherit pkgs lib; }).fonts.packages;
    })
  ];
  launchd.daemons.tailscaled.config.KeepAlive = true;

  environment.files."pam.d/sudo_local" = {
    text = "auth sufficient pam_tid.so\n";
    known.macOS = true;
    known.hashes = [
      (builtins.hashString "sha256" "auth       sufficient     pam_tid.so\n")
    ];
  };
  system.activation.steps.remote-login = {
    deps = [ "files" ];
    text = ''
      /bin/launchctl enable system/com.openssh.sshd
      if ! /bin/launchctl print system/com.openssh.sshd >/dev/null 2>&1; then
        /bin/launchctl bootstrap system /System/Library/LaunchDaemons/ssh.plist
      fi
    '';
  };
  environment.files."ssh/authorized_keys.d/ashuramaru".text =
    lib.concatStringsSep "\n" (import ../../../keys/ashuramaru.nix) + "\n";
  environment.files."ssh/sshd_config.d/100-authorized-keys.conf".text = ''
    AuthorizedKeysFile .ssh/authorized_keys /etc/ssh/authorized_keys.d/%u
  '';

  sops.secrets.tailscale_auth = { };

  # Retry until the secret and tailscaled are ready
  launchd.daemons.tailscale-autoconnect = {
    enable = true;
    path = [ pkgs.jq ];
    script = ''
      set -euo pipefail

      tailscale() {
        ${lib.meta.getExe' pkgs.tailscale "tailscale"} \
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
    config = {
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

  users.users.ashuramaru = {
    uid = 501;
    home = "/Users/ashuramaru";
    description = "Maria Głowata";
    shell = pkgs.zsh;
  };

  programs.pared.features.mailSummaries = true;

  nixpkgs.config.permittedInsecurePackages = [
    "electron-39.8.10"
  ];

  environment.system.packages = lib.attrsets.attrValues {
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
  # instead of a separate NixOS VM builder
  determinateNix.determinateNixd.builder.state = "enabled";
}
