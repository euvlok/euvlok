{
  pkgs,
  lib,
  config,
  ...
}:
{
  fonts.packages =
    builtins.attrValues { inherit (pkgs.nerd-fonts) monaspace noto; }
    ++ lib.optionals config.nixos.gnome.enable (
      builtins.attrValues { inherit (pkgs.nerd-fonts) adwaita-mono; }
    );
}
