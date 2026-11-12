{ pkgs, ... }:
{
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      # Let Plasma's Wayland input protocol handle native clients
      waylandFrontend = true;
      addons = [
        pkgs.fcitx5-mozc
        pkgs.qt6Packages.fcitx5-unikey
      ];
    };
  };
}
