{
  pkgs,
  lib,
  config,
  ...
}:
{
  imports = [
    ./audio.nix
    ./gnome.nix
    ./hardware.nix
    ./kanata.nix
    ./networking.nix
    ./nix.nix
    ./plasma.nix
    ./security.nix
    ./services.nix
    ./sessionVariables.nix
    ./steam.nix
    ./zram.nix
  ];

  config = lib.mkMerge [
    (lib.mkIf (config.nixos.plasma.enable or config.nixos.gnome.enable) {
      xdg.portal = {
        enable = true;
        wlr.enable = true;
        xdgOpenUsePortal = true;
        extraPortals = builtins.attrValues {
          inherit (pkgs)
            xdg-desktop-portal-gtk
            ;
        };
      };
    })
  ];
}
