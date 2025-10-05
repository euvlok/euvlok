{ inputs, eulib, ... }:
{
  blind-faith = inputs.nixpkgs-lay-by.lib.nixosSystem {
    specialArgs = { inherit inputs eulib; };
    modules = [
      ./configuration.nix
      ./home.nix
      inputs.catppuccin-trivial.nixosModules.catppuccin

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
      (
        { config, ... }:
        {
          _module.args.pkgsUnstable = import inputs.nixpkgs-unstable {
            system = "x86_64-linux";
            config = config.nixpkgs.config;
          };
        }
      )
    ];
  };
}
