{ inputs, eulib, ... }:
{
  null = inputs.nixpkgs-sm-idk.lib.nixosSystem {
    specialArgs = { inherit inputs eulib; };
    modules = [
      inputs.catppuccin-trivial.nixosModules.catppuccin
      (
        { config, ... }:
        {
          _module.args.pkgsUnstable = import inputs.nixpkgs-unstable-small {
            system = "x86_64-linux";
            config = config.nixpkgs.config;
          };
        }
      )
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
      inputs.chaotic.nixosModules.nyx-cache
      inputs.chaotic.nixosModules.nyx-overlay
      inputs.chaotic.nixosModules.nyx-registry
      ./configuration.nix
      ./home.nix
    ];
  };
}
