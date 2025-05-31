{
  pkgs,
  lib,
  config,
  ...
}:
{
  fonts = {
    enableDefaultPackages = true;
    fontDir.enable = true;
    fontconfig.defaultFonts = {
      monospace = [ "Monaspice Kr Nerd Font" ];
      sansSerif = [ "Noto Nerd Font" ];
      serif = [ "Noto Nerd Font" ];
      emoji = [ "Twitter Color Emoji" ];
    };
    packages =
      builtins.attrValues {
        inherit (pkgs) noto-fonts-cjk-sans noto-fonts-emoji twemoji-color-font;
        inherit (pkgs.nerd-fonts) monaspace noto;
      }
      ++ lib.optionals config.nixos.gnome.enable (
        builtins.attrValues { inherit (pkgs.nerd-fonts) adawaita-mono; }
      );
  };
}
