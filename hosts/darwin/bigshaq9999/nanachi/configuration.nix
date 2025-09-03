{
  inputs,
  pkgs,
  eulib,
  ...
}:
{
  imports = [
    inputs.sops-nix-trivial.darwinModules.sops
    {
      sops = {
        age.keyFile = "/var/lib/sops/age/keys.txt";
        age.sshKeyPaths = [ ]; # we don't need this shit here
        defaultSopsFile = ../../../../secrets/bigshaq9999.yaml;
      };
    }
  ];

  system.primaryUser = "faputa";

  nixpkgs.hostPlatform.system = "aarch64-darwin";

  networking = {
    computerName = "Marie's boyfriend's Mac Mini M4 Pro nanachi";
    hostName = "faputas-Mac-mini.local";
    localHostName = "faputa";
    knownNetworkServices = [
      "Ethernet"
      "Thunderbolt Bridge"
      "Wi-Fi"
    ];
    dns = [
      "192.168.1.1"
      "172.16.31.3"
      "fd17:216b:31bc:3::1"
    ];
  };

  users.users = {
    faputa = {
      home = "/Users/faputa";
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

      gnupg
      ;
  };
}
