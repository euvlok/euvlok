{ inputs, eulib, ... }:
{
  nyx = inputs.nixpkgs-donteatoreo.lib.nixosSystem {
    specialArgs = { inherit inputs eulib; };
    modules = [
      ./configuration.nix
      ./home.nix
      inputs.catppuccin-trivial.nixosModules.catppuccin
      {
        catppuccin = {
          enable = true;
          flavor = "frappe";
          accent = "teal";
        };
      }

      ../../../../modules/nixos
      ../../../../modules/cross
      {
        nixos = {
          amd.enable = true;
          nvidia.enable = true;
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
