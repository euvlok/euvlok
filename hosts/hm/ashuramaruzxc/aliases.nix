{ pkgs, lib, ... }:
let
  aliases = {
    video2gif = lib.getExe (pkgs.writeScriptBin "video2gif" (builtins.readFile ./scripts/video2gif.sh));
  };
in
{
  programs.bash.shellAliases = aliases;
  programs.zsh.shellAliases = aliases;
}
