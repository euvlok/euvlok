# Lay-by's personal theme, shared only between their machines.
{ pkgs, ... }:
let
  monospace = {
    package = pkgs.nerd-fonts.iosevka;
    name = "Iosevka Nerd Font Mono";
  };
in
{
  stylix = {
    enable = true;
    polarity = "dark";
    autoEnable = false;
    image = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/lay-by/wallpapers/00fb754880396b15a536964499bcce25208fae48/starfighter2.png";
      hash = "sha256-eDeJpTVmEt6Ty0HL7KVKe+O6Sgcv8lKX2FlLQwm+v+I";
    };
    base16Scheme = ../../../hm/lay-by/tokyo-night-terminal-dark.yaml;
    cursor = {
      package = pkgs.kdePackages.breeze;
      name = "Breeze-Dark";
      size = 24;
    };
    fonts = {
      inherit monospace;
      serif = monospace;
      sansSerif = monospace;
      emoji = {
        package = pkgs.twemoji-color-font;
        name = "Twitter Color Emoji";
      };
    };
  };
}
