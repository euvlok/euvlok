{
  config,
  ...
}:
{
  programs.ssh = {
    enableDefaultConfig = false;
    settings = {
      "*" = {
        Compression = false;
        ControlMaster = "no";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "no";
        ForwardAgent = false;
        HashKnownHosts = false;
        IdentitiesOnly = true;
        ServerAliveCountMax = 3;
        ServerAliveInterval = 0;
        UserKnownHostsFile = "~/.ssh/known_hosts";
        IdentityFile = [ "${config.home.homeDirectory}/.ssh/id_ed25519-sk" ];
      };

      "github.com" = {
        HostName = "ssh.github.com";
        Port = 443;
        User = "git";
        IdentityFile = [ "${config.home.homeDirectory}/.ssh/id_ecdsa-sk_github" ];
      };

      "initrd.tenjin.com" = {
        HostName = "www.tenjin-dk.com";
        Port = 2222;
      };

      "www.tenjin-dk.com" = {
        HostName = "www.tenjin-dk.com";
        Port = 57255;
      };

      "tenjin-dk.com" = {
        HostName = "www.tenjin-dk.com";
        Port = 57255;
      };

      "unsigned-int4.home.lan" = {
        HostName = "192.168.50.15";
        Port = 22;
        IdentityFile = [ "${config.home.homeDirectory}/.ssh/id_ecdsa-sk" ];
      };
    };
  };
  services.ssh-agent = {
    enable = true;
  };
}
