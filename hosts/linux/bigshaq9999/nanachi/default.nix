{ inputs, euvlok, ... }:
{
  nanachi = inputs.nixpkgs-bigshaq9999.lib.nixosSystem {
    specialArgs = { inherit inputs euvlok; };
    modules = [
      ./configuration.nix
      ./home.nix
      inputs.catppuccin-trivial.nixosModules.catppuccin
      {
        catppuccin = {
          enable = true;
          flavor = "frappe";
          accent = "blue";
        };
      }

      ../../../../modules/nixos
      ../../../../modules/cross
      {
        nixos.gnome.enable = true;
        cross = {
          nix.enable = true;
          nixpkgs.enable = true;
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
