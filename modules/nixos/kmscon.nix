{
  config,
  lib,
  pkgs,
  ...
}:
let
  palette = lib.trivial.importJSON (config.catppuccin.sources.palette + /palette.json);
  # kmscon expects decimal RGB triples rather than hexadecimal colors
  colors = lib.attrsets.mapAttrs (
    _: color:
    let
      inherit (color.rgb) r g b;
    in
    lib.strings.concatStringsSep "," (
      map toString [
        r
        g
        b
      ]
    )
  ) palette.${config.catppuccin.flavor}.colors;
in
{
  services.kmscon = {
    enable = lib.modules.mkDefault true;
    useXkbConfig = lib.modules.mkDefault true;
    config = lib.modules.mkMerge [
      {
        # Keep software rendering available on hosts without a graphics stack
        hwaccel = lib.modules.mkDefault config.hardware.graphics.enable;
        # FreeType uses light hinting and grayscale anti-aliasing
        font-engine = lib.modules.mkDefault "freetype";
        font-name = lib.modules.mkDefault "Hack Nerd Font Mono";
        # Let kmscon choose a readable pixel size for each display
        font-size = lib.modules.mkDefault 0;
        term = lib.modules.mkDefault "kmscon";
        sb-size = lib.modules.mkDefault 10000;
      }
      (lib.modules.mkIf (config.catppuccin.enable && config.services.kmscon.enable) (
        lib.attrsets.mapAttrs (_: lib.modules.mkDefault) {
          # Match catppuccin/tty's ANSI colors with explicit text and background
          palette = "custom";
          palette-black = colors.base;
          palette-red = colors.red;
          palette-green = colors.green;
          palette-yellow = colors.yellow;
          palette-blue = colors.blue;
          palette-magenta = colors.pink;
          palette-cyan = colors.teal;
          palette-light-grey = colors.subtext1;
          palette-dark-grey = colors.surface2;
          palette-light-red = colors.red;
          palette-light-green = colors.green;
          palette-light-yellow = colors.yellow;
          palette-light-blue = colors.blue;
          palette-light-magenta = colors.pink;
          palette-light-cyan = colors.teal;
          palette-white = colors.subtext0;
          palette-foreground = colors.text;
          palette-background = colors.base;
        }
      ))
    ];
  };

  fonts = lib.modules.mkIf config.services.kmscon.enable {
    fontconfig = {
      enable = true;
      antialias = lib.modules.mkDefault true;
    };
    packages = lib.attrsets.attrValues {
      inherit (pkgs) noto-fonts noto-fonts-cjk-sans noto-fonts-color-emoji;
      inherit (pkgs.nerd-fonts) hack;
    };
  };
}
