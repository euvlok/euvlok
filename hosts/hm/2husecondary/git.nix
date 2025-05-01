{ pkgs, ... }:
let
  userName = "2husecondary";
  userEmail = "158063550+2husecondary@users.noreply.github.com";
in
{
  home.packages = builtins.attrValues { inherit (pkgs) watchman; };

  programs = {
    gh.gitCredentialHelper.enable = true;
    gh.settings.git_protocol = "ssh";
    git = {
      inherit userName userEmail;
      lfs.enable = true;
    };
    git-credential-oauth.enable = true;
  };
}
