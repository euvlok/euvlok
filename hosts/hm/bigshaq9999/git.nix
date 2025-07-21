_:
let
  userName = "bigshaq9999";
in
{
  # home.packages = builtins.attrValues { inherit (pkgs) watchman; };

  programs = {
    gh.gitCredentialHelper.enable = true;
    # gh.settings.git_protocol = "ssh";
    gitui.enable = true;
    gh.enable = true;
    git = {
      inherit userName;
      lfs.enable = true;
    };
    git-credential-oauth.enable = true;
  };
}
