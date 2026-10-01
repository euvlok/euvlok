{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.euvlok.catppuccinGtk;
  package = pkgs.callPackage ../../packages/catppuccin-gtk.nix {
    inherit (cfg)
      accent
      flavor
      size
      rimless
      ;
  };
in
{
  options.euvlok.catppuccinGtk = {
    enable = lib.mkEnableOption "Catppuccin GTK theme by Fausto-Korpsvart";
    flavor = lib.mkOption {
      type = lib.types.enum [
        "latte"
        "frappe"
        "macchiato"
        "mocha"
      ];
      default = "mocha";
      description = "Catppuccin color palette used by the GTK theme.";
    };
    accent = lib.mkOption {
      type = lib.types.enum [
        "blue"
        "flamingo"
        "green"
        "lavender"
        "maroon"
        "mauve"
        "peach"
        "pink"
        "red"
        "rosewater"
        "sapphire"
        "sky"
        "teal"
        "yellow"
      ];
      default = "mauve";
      description = "Accent color used by the GTK theme.";
    };
    size = lib.mkOption {
      type = lib.types.enum [
        "standard"
        "compact"
      ];
      default = "standard";
      description = "Widget size of the GTK theme.";
    };
    rimless = lib.mkEnableOption "GTK windows and menus without border rims";
  };

  config = lib.mkIf cfg.enable {
    gtk.enable = lib.mkDefault true;
    gtk.theme = {
      name = package.themeName;
      inherit package;
    };
    gtk.gtk4.theme = lib.mkDefault config.gtk.theme;
  };
}
