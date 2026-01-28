{ inputs, ... }:
{
  blind-faith = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit inputs; };
    modules = [
      inputs.self.nixosModules.default
      ./configuration.nix
      ./home.nix
    ]
    ++ [
      {
        nixos = {
          nvidia.enable = true;
          steam.enable = true;
        };
      }
    ];
  };
}
