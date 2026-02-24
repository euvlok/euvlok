{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.ssh = {
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        compression = false;
        controlMaster = "no";
        controlPath = "~/.ssh/master-%r@%n:%p";
        controlPersist = "no";
        forwardAgent = false;
        hashKnownHosts = false;
        identitiesOnly = true;
        serverAliveCountMax = 3;
        serverAliveInterval = 0;
        userKnownHostsFile = "~/.ssh/known_hosts";
        identityFile = [ "${config.home.homeDirectory}/.ssh/id_ed25519-sk" ];
      };

      "github.com" = {
        hostname = "ssh.github.com";
        port = 443;
        user = "git";
        identityFile = [ "${config.home.homeDirectory}/.ssh/id_ecdsa-sk_github" ];
      };

      "initrd.tenjin.com" = {
        hostname = "www.tenjin-dk.com";
        port = 2222;
      };

      "www.tenjin-dk.com" = {
        hostname = "www.tenjin-dk.com";
        port = 57255;
      };

      "tenjin-dk.com" = {
        hostname = "www.tenjin-dk.com";
        port = 57255;
      };

      "unsigned-int4.home.lan" = {
        hostname = "192.168.50.15";
        port = 22;
        identityFile = [ "${config.home.homeDirectory}/.ssh/id_ecdsa-sk" ];
      };
    };
  };
  services.ssh-agent = {
    enable = true;
  };
}
