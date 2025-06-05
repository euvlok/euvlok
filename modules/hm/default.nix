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
    (lib.mkIf (config.hm.hyprland.enable) {
      xdg.portal.extraPortals = builtins.attrValues {
        inherit (inputs.hyprland-source.packages.${pkgs.stdenv.hostPlatform.system})
          xdg-desktop-portal-hyprland
          ;
      };
    })
    (lib.mkIf (config.hm.niri.enable) {
      xdg.portal.extraPortals = builtins.attrValues {
        inherit (pkgs)
          xdg-desktop-portal-gnome
          xdg-desktop-portal-shana
          xdg-desktop-portal-wlr
          ;
      };
    })
  ];
}
