{ inputs, ... }:
{
  nyx = inputs.nixpkgs-donteatoreo.lib.nixosSystem {
    specialArgs = { inherit inputs; };
    modules = [
      ./configuration.nix
      ./home.nix
      inputs.catppuccin.nixosModules.catppuccin

      ../../../../modules/nixos
      ../../../../modules/cross
      {
        nixos.nvidia.enable = true;
        cross = {
          nix.enable = true;
          nixpkgs = {
            enable = true;
            allowUnfree = true;
            cudaSupport = true;
          };
        };
      }
    ];
  };
}
