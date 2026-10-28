{
  lib,
  pkgs,
  ...
}:
{
  imports = [
    { sops.defaultSopsFile = ../../../../secrets/bigshaq9999.yaml; }
    ../../../../modules/darwin/host-services.nix
  ];

  system.primary.user = "faputa";

  networking = {
    computerName = "Marie's boyfriend's Mac Mini M4 Pro faputa";
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
  environment.files."resolver/ts.net" = {
    text = "nameserver 100.100.100.100";
    known.hashes = [
      "2c28f4fe3b4a958cd86b120e7eb799eee6976daa35b228c885f0630c55ef626c"
    ];
  };

  users.users = {
    faputa = {
      uid = 501;
      home = "/Volumes/Reg/Users/faputa";
      shell = pkgs.zsh;
    };
  };

  # Environment
  environment.system.packages = lib.attrsets.attrValues {
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
