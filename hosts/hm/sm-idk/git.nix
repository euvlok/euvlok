{ config, ... }:
let
  userName = "sm-idk";
  userEmail = "43745781+sm-idk@users.noreply.github.com";
in
{
  programs.gh.enable = true;
  programs.git = {
    enable = true;
    inherit userName userEmail;
  };
  home.file.".gitconfig".source =
    config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/git/config";
}
