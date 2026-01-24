{ inputs, ... }:
{
  null = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit inputs; };
    modules = [
      inputs.self.nixosModules.default
      ./configuration.nix
      ./home.nix
      inputs.catppuccin-trivial.nixosModules.catppuccin
    ]
    ++ [
      {
        nixos = {
          nvidia.enable = true;
          steam.enable = true;
          gnome.enable = true;
        };
      }
    ];
  };
}
