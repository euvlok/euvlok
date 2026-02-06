{
  config,
  pkgs,
  lib,
  ...
}:

{
  stylix = {
    enable = true;
    polarity = "dark";
    autoEnable = true;

    targets.hyprlock.enable = false;
    targets.spicetify.enable = true;
    targets.zen-browser.enable = false;
    targets.rofi.enable = false;
    # targets.anki.enable = false;
    # targets.hyprpaper.enable = false;

    image = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/lay-by/wallpapers/refs/heads/main/starfighter2.png";
      hash = "sha256-eDeJpTVmEt6Ty0HL7KVKe+O6Sgcv8lKX2FlLQwm+v+I";
    };
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
