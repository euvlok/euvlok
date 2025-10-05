{ config, pkgs, ... }:

{
  stylix = {
    enable = true;
    polarity = "dark";
    autoEnable = true;

    targets.hyprlock.enable = false;
    targets.spicetify.enable = false;
    #targets.hyprpaper.enable = false;

    image = /home/hushh/Pictures/papes/city.jpg;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-terminal-dark.yaml";

    cursor = {
      package = pkgs.kdePackages.breeze;
      name = "Breeze-Dark";
      size = 24;
    };

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.iosevka;
        name = "Iosevka Nerd Font Mono";
      };

      emoji = {
        package = pkgs.twemoji-color-font;
        name = "Twitter Color Emoji";
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
