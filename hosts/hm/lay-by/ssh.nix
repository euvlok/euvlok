{ config, pkgs, ... }:
{
  programs.ssh = {
    enable = true;
    matchBlocks = {
      # Define your alias name, e.g., "myserver"
      "minecraft" = {
        hostname = "192.168.1.30"; # e.g., "10.10.20.20"
        user = "hushh"; # e.g., "user"
        # Optional: specify a custom port
        # port = 2222;
        # Optional: specify an identity file managed by home-manager
        # identityFile = config.specialisation.home.users.youruser.programs.ssh.identityFiles."yourkey";
      };
    };
  };
}
