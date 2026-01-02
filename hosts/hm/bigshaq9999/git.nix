{ lib, ... }:
let
  name = "bigshaq9999";
  email = "97749920+bigshaq9999@users.noreply.github.com";
in
{
  # home.packages = builtins.attrValues { inherit (pkgs) watchman; };

  programs = {
    gh.gitCredentialHelper.enable = true;
    # gh.settings.git_protocol = "ssh";
    gitui.enable = lib.mkForce false;
    gh.enable = true;
    git = {
      settings.user.name = name;
      settings.user.email = email;
      lfs.enable = true;
    };
    # git-credential-oauth.enable = true;
  };
}
