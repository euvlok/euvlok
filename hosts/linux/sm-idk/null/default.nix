{ inputs, ... }:
{
  null = inputs.nixpkgs-sm-idk.lib.nixosSystem {
    specialArgs = { inherit inputs; };
    modules = [
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
      ../../../../modules/nixos
      ../../../../modules/cross
      {
        nixos = {
          nvidia.enable = true;
          steam.enable = true;
          gnome.enable = true;
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
