{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
{
  imports = [
    ./cli
    ./gui
    ./languages.nix
    ./shell
    ./terminal
    ./tui
    ./wm
  ];

  config = lib.mkMerge [
    ({
      xdg.portal.extraPortals = builtins.attrValues {
        inherit (inputs.hyprland-source.packages.${pkgs.stdenv.hostPlatform.system})
          xdg-desktop-portal-gnome
          xdg-desktop-portal-hyprland
          xdg-desktop-portal-shana
          xdg-desktop-portal-wlr
          ;
      };
    })
  ];
}
