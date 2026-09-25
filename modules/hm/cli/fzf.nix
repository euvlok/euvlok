{
  lib,
  pkgs,
  ...
}:
{
  programs.fzf = {
    enable = lib.modules.mkDefault true;
    package = pkgs.unstable.fzf;
  };
}
