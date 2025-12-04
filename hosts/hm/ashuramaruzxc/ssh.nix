{ lib, config, ... }:
{
  programs.ssh = {
    enableDefaultConfig = false;
    matchBlocks."*" = {
      addKeysToAgent = "no";
    };
    extraConfig = ''
    Host *
        IdentitiesOnly yes
        IdentityFile "${config.home.homeDirectory}/.ssh/id_ed25519-sk"
      
      Host github.com
        Hostname ssh.github.com
        Port 443
        User git
        IdentityFile "${config.home.homeDirectory}/.ssh/id_ecdsa-sk_github"
      
      Host initrd.tenjin.com
        Hostname www.tenjin-dk.com
        Port 2222
      Host www.tenjin-dk.com
        Hostname www.tenjin-dk.com
        Port 57255
      Host tenjin-dk.com
        Hostname www.tenjin-dk.com
        Port 57255
      Host unsigned-int4.home.lan
        Hostname 192.168.50.15
        Port 22
        IdentityFile "${config.home.homeDirectory}/.ssh/id_ecdsa-sk"
  '';
}
