# workaround for https://github.com/catppuccin/nix/pull/644

{
  lib,
  config,
  inputs,
  pkgs,
  ...
}:
let
  catppuccinLib = import (inputs.catppuccin-trivial + /modules/lib) { inherit lib config pkgs; };
  renamedGtkOption = "i-still-want-to-use-the-archived-gtk-theme-because-it-works-better-than-everything-else";
  cfg = config.catppuccin.${renamedGtkOption};
  enable = cfg.enable && config.gtk.enable;
in
{
  options.catppuccin.${renamedGtkOption} =
    (catppuccinLib.mkCatppuccinOption {
      name = "gtk";
      accentSupport = true;
    })
    // {
      size = lib.mkOption {
        type = lib.types.enum [
          "standard"
          "compact"
        ];
        default = "standard";
        description = "Catppuccin size variant for gtk";
      };
      tweaks = lib.mkOption {
        type = lib.types.listOf (
          lib.types.enum [
            "rimless"
            "normal"
          ]
        );
        default = [ ];
        description = "Catppuccin tweaks for gtk";
      };
    };
  config = lib.mkMerge [
    (lib.mkIf enable {
      gtk.theme =
        let
          gtkTweaks = lib.concatStringsSep "," cfg.tweaks;
          themeName =
            "catppuccin-${cfg.flavor}-${cfg.accent}-${cfg.size}+"
            + (if cfg.tweaks == [ ] then "default" else gtkTweaks);
        in
        {
          name = themeName;
          package = config.catppuccin.sources.gtk.override {
            inherit (cfg) flavor size tweaks;
            accents = [ cfg.accent ];
          };
        };
      xdg.configFile =
        let
          gtk4Dir = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0";
        in
        {
          "gtk-4.0/assets".source = "${gtk4Dir}/assets";
          "gtk-4.0/gtk.css".source = "${gtk4Dir}/gtk.css";
          "gtk-4.0/gtk-dark.css".source = "${gtk4Dir}/gtk-dark.css";
        };
    })
    {
      catppuccin.sources.gtk = inputs.catppuccin-gtk.packages.${pkgs.stdenvNoCC.hostPlatform.system}.gtk;
    }
  ];
}
