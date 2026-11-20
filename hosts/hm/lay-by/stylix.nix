{
  config,
  lib,
  pkgs,
  ...
}:
{
  stylix = {
    autoEnable = true;
    targets.hyprlock.enable = false;
    targets.spicetify.enable = true;
    targets.zen-browser.enable = false;
    targets.rofi.enable = false;
    # targets.anki.enable = false;
    # targets.hyprpaper.enable = false;
  };

  home.pointerCursor.enable = true;

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
    gtk4.theme = lib.modules.mkDefault config.gtk.theme;
  };
}
