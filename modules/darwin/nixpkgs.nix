{ config, ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      catppuccin-userstyles = final.callPackage ../../pkgs/catppuccin-userstyles.nix {
        inherit (config.catppuccin) accent;
      };
    })
  ];
}
