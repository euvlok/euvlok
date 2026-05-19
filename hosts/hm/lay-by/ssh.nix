{ ... }:
{
  programs.ssh = {
    enable = true;
    settings = {
      # Define your alias name, e.g., "myserver"
      "minecraft" = {
        HostName = "192.168.1.30"; # e.g., "10.10.20.20"
        User = "hushh"; # e.g., "user"
        # Optional: specify a custom port
        # Port = 2222;
        # Optional: specify an identity file managed by home-manager
        # IdentityFile = config.specialisation.home.users.youruser.programs.ssh.identityFiles."yourkey";
      };
    };
  };
}
