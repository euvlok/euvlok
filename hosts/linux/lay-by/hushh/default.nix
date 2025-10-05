
{ inputs, ... }:
{
  blind-faith = inputs.nixpkgs-lay-by.lib.nixosSystem {
    specialArgs = { inherit inputs; };
    modules = [
      ./configuration.nix
      ./home.nix
      inputs.catppuccin-trivial.nixosModules.catppuccin
    ]
    ++ [
      ../../../../modules/nixos
      ../../../../modules/cross
      {
        nixos = {
          nvidia.enable = true;
          steam.enable = true;
        };
        cross = {
          nix.enable = true;
          nixpkgs = {
            enable = true;
            cudaSupport = true;
          };
        };
      }
    ];
  };
}