{ pkgs, ... }:
let
  userName = "Tenjin";
  userEmail = "ashuramaru@tenjin-dk.com";
  format = "openpgp";
  key = "409D201E94508732A49ED0FC6BDAF874006808DF";
in
{
  home.packages = builtins.attrValues { inherit (pkgs) watchman; };

  programs = {
    gh.gitCredentialHelper.enable = true;
    gh.settings.git_protocol = "ssh";
    git = {
      inherit userName userEmail;
      signing = {
        inherit key format;
        signByDefault = true;
      };
      lfs.enable = true;
      aliases = {
        "lg" =
          "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      };
    };
    git-credential-oauth.enable = true;
  };
}
