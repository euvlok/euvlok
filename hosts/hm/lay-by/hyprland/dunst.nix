{ pkgs, ... }:
{
  services.dunst = {
    enable = true;
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
      size = "32x32";
    };
    settings = {
      global = {
        width = 300;
        height = 150;
        origin = "bottom-right";
        offset = "10x10";
        transparency = 70;
        frame_width = 1;
        corner_radius = 5;
      };
    };
  };
}
