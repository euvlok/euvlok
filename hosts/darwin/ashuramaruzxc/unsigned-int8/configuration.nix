{ containerPackage }:
{
  pkgs,
  ...
}:
{
  # imports = [
  # {
  # sops = {
  # age.keyFile = "/var/lib/sops/age/keys.txt";
  # age.sshKeyPaths = [ ]; # we don't need this shit here
  # defaultSopsFile = ../../../../secrets/ashuramaruzxc_unsigned-int8.yaml;
  # secrets.id_ecdsa-sk_github = {
  #  mode = "0600";
  # owner = config.users.users.ashuramaru.name;
  # neededForUsers = true;
  # };
  # };
  # }
  # ];

  imports = [
    ../../../linux/ashuramaruzxc/shared/system/fonts.nix
  ];
  system.primaryUser = "ashuramaru";

  nixpkgs.hostPlatform = "aarch64-darwin";

  security.pam.services.sudo_local.touchIdAuth = true;
  services.openssh.enable = true;
  networking = {
    computerName = "Marie's Macbook Pro 16 M4 Max unsigned-int8";
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

  environment.systemPackages = builtins.attrValues {
    container = containerPackage;

    inherit (pkgs.unstable)
      # Literally should be bultin but apple being apple
      # Utils
      wireguard-tools
      smartmontools
      # Virtualization
      colima
      docker
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
