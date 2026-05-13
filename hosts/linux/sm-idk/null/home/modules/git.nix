{
  config,
  pkgs,
  ...
}:
let
  name = "sm-idk";
  email = "43745781+sm-idk@users.noreply.github.com";
in
{
  programs.gh.enable = true;
  programs.git = {
    settings.user = {
      inherit name email;
    };
    enable = true;
    package = pkgs.gitMinimal;
  };
  home.file.".gitconfig".source =
    config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/git/config";
}
