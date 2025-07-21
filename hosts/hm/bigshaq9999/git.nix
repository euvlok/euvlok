_:
let
  userName = "bigshaq9999";
  userEmail = "97749920+bigshaq9999@users.noreply.github.com";
in
{
  # home.packages = builtins.attrValues { inherit (pkgs) watchman; };

  programs = {
    gh.gitCredentialHelper.enable = true;
    # gh.settings.git_protocol = "ssh";
    gitui.enable = true;
    gh.enable = true;
    git = {
      inherit userName userEmail;
      lfs.enable = true;
    };
    # git-credential-oauth.enable = true;
  };
}
