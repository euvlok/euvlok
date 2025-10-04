{ config, pkgs, ... }:
{
  stylix = {
    enable = true;
    polarity = "dark";
    autoEnable = true;

    targets.hyprlock.enable = false;
    targets.spicetify.enable = false;
    targets.firefox.profileNames = "default";

    image = "/home/hushh/Pictures/papes/city.jpg";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-terminal-dark.yaml";

    cursor = {
      size = 24;
      package = pkgs.kdePackages.breeze;
      name = "Breeze-Dark";
    };

    fonts = {
      monospace = {
        name = "Iosevka Nerd Font Mono";
        package = pkgs.nerd-fonts.iosevka;
      };
      emoji = {
        name = "Twitter Color Emoji";
        package = pkgs.twemoji-color-font;
      };
      serif = config.stylix.fonts.monospace;
      sansSerif = config.stylix.fonts.monospace;
    };
  };

  gtk = {
    enable = true;
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = {
      name = "Breeze-Dark";
      package = pkgs.kdePackages.breeze-gtk;
    };
  };
}
