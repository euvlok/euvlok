{ inputs, ... }:
{
  blind-faith = inputs.nixpkgs-lay-by.lib.nixosSystem {
    specialArgs = { inherit inputs; };
    modules = [
      inputs.self.nixosModules.default
      ./configuration.nix
      ./home.nix
      inputs.catppuccin-trivial.nixosModules.catppuccin
    ]
    ++ [
      inputs.self.crossModules.default
      {
        nixos = {
          nvidia.enable = true;
          steam.enable = true;
        };
      }
    ];
  };
}
