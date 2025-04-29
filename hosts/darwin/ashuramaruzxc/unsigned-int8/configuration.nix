{
  inputs,
  pkgs,
  config,
  ...
}:
{
  imports = [
    inputs.sops-nix.darwinModules.sops
    {
      sops = {
        age.keyFile = "/var/lib/sops/age/keys.txt";
        age.sshKeyPaths = [ ]; # we don't need this shit here
        defaultSopsFile = ../../../../secrets/ashuramaruzxc_unsigned-int8.yaml;
        secrets.ssh_ed25519-sk_github = {
          mode = "0600";
          owner = config.users.users.ashuramaru.name;
          neededForUsers = true;
        };
      };
    }
  ];
  nixpkgs.hostPlatform.system = "aarch64-darwin";

  security.pam.services.sudo_local.touchIdAuth = true;

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

      # fine lol
      pinentry_mac
      gnupg
      ;
  };
}
