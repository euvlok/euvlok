{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.euvlok.nixos.gnome.enable {
    environment.systemPackages = lib.attrsets.attrValues {
      inherit (pkgs.unstable)
        gnome-themes-extra
        gnome-tweaks
        gparted
        pop-launcher
        ;
      inherit (pkgs.unstable.gnomeExtensions)
        arcmenu
        auto-move-windows
        blur-my-shell
        dash-to-dock
        gsconnect
        kimpanel
        pop-shell
        rounded-corners
        smart-auto-move
        system-monitor
        user-themes
        ;
    };
  };
}
