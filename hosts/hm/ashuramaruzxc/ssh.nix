{ config, ... }:
{
  programs.ssh.extraConfig = ''
    Host github.com
      Hostname ssh.github.com
      Port 443
      User git
      IdentityFile "${config.home.homeDirectory}/.ssh/id_ed25519-sk_github"
      IdentityFile "${config.home.homeDirectory}/.ssh/id_ecdsa-sk_github"
  '';
}
