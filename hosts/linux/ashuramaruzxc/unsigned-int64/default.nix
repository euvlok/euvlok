{ inputs, ... }:
{
  unsigned-int64 = inputs.nixpkgs-ashuramaruzxc.lib.nixosSystem {
    specialArgs = { inherit inputs; };
    modules = [
      ../../shared/configuration.nix
      ./configuration.nix
      ./home.nix
      inputs.catppuccin.nixosModules.catppuccin

      ../../../../modules/nixos
      ../../../../modules/cross
      {
        cross = {
          nix.enable = true;
          nixpkgs.enable = true;
        };
      }
    ];
  };
}
