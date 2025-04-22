{ config, osConfig, ... }:
let
  home = config.home.homeDirectory;
  sockPath =
    if osConfig.nixpkgs.hostPlatform.isDarwin then
      "Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    else
      ".1password/agent.sock";
in
{
  home.sessionVariables = {
    SSH_AUTH_SOCK = "${home}/${sockPath}";
  };
  programs.ssh.extraConfig = ''
    Host *
      IdentityAgent "${home}/${sockPath}"

    Host github.com
      Hostname ssh.github.com
      Port 443
      User git
      IdentityFile ${config.sops.secrets.github_ssh.path}
  '';
}
