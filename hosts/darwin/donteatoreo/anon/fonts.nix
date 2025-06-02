{
  pkgs,
  lib,
  config,
  ...
}:
{
  fonts.packages = builtins.attrValues { inherit (pkgs.nerd-fonts) monaspace noto; };
}
