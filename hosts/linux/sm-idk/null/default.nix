{ inputs, ... }:
{
  null = inputs.nixpkgs-sm-idk.lib.nixosSystem {
    specialArgs = { inherit inputs; };
    modules = [
      inputs.self.nixosModules
      ./configuration.nix
      ./home.nix
      inputs.catppuccin-trivial.nixosModules.catppuccin
    ]
    ++ [
      inputs.chaotic.nixosModules.nyx-cache
      inputs.chaotic.nixosModules.nyx-overlay
      inputs.chaotic.nixosModules.nyx-registry
    ]
    ++ [
      inputs.self.crossModules
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
