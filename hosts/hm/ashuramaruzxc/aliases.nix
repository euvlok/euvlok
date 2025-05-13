{ pkgs, lib, ... }:
let
  utils = {
    video2gif = lib.getExe (
      pkgs.writeScriptBin "video2gif" (builtins.readFile ../../../pkgs/scripts/ashuramaruzxc/video2gif.sh)
    );
  };
in
{
  programs.bash.shellAliases = utils;
  programs.zsh.shellAliases = utils;
}
