{ pkgs, ... }:
{
  home.packages = builtins.attrValues { inherit (pkgs) watchman; };

  programs = {
    gh.gitCredentialHelper.enable = true;
    gh.settings.git_protocol = "ssh";
    git = {
      enable = true;
      settings = {
        user = {
          name = "ashuramaruzxc";
          email = "ashuramaru@tenjin-dk.com";
          signingkey = "409D201E94508732A49ED0FC6BDAF874006808DF";
        };
        commit.gpgsign = true;
        gpg.format = "openpgp";
        filter.lfs = {
          clean = "git-lfs clean -- %f";
          smudge = "git-lfs smudge -- %f";
          process = "git-lfs filter-process";
          required = true;
        };
        alias.lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      };
    };
    git-credential-oauth.enable = true;
  };
}
