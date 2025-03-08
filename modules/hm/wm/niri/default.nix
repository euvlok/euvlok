{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
{
  imports = [
    inputs.niri-flake.homeModules.niri
    ./binds.nix
    ./settings.nix
  ];

  options.hm.niri.enable = lib.mkEnableOption "Niri";

  config = lib.mkIf config.hm.niri.enable {
    programs.niri.enable = true;
    xdg = {
      enable = true;
      portal = {
        enable = true;
        xdgOpenUsePortal = true;
        config = {
          common = {
            default = [
              "gtk"
              "gnome"
            ];
            # Fix Screensharing
            "org.freedesktop.impl.portal.ScreenCast" = "gnome";
            "org.freedesktop.impl.portal.Screenshot" = "gnome";
            "org.freedesktop.impl.portal.RemoteDesktop" = "gnome";
          };
        };
        extraPortals = builtins.attrValues {
          inherit (pkgs)
            xdg-desktop-portal
            xdg-desktop-portal-gtk
            xdg-desktop-portal-gnome
            xdg-desktop-portal-shana
            xdg-desktop-portal-wlr
            ;
        };
        configPackages = builtins.attrValues { inherit (pkgs) gnome-session; };
      };
      mime.enable = true;
    };
  };
}
