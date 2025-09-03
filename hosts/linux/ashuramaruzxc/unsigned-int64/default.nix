{ inputs, eulib, ... }:
{
  unsigned-int64 = inputs.nixpkgs-ashuramaruzxc.lib.nixosSystem {
    specialArgs = { inherit inputs eulib; };
    modules = [
      ./configuration.nix
      ./home.nix
      inputs.sops-nix-trivial.nixosModules.sops
      {
        sops = {
          age.keyFile = "/var/lib/sops/age/keys.txt";
          defaultSopsFile = ../../../../secrets/ashuramaruzxc_unsigned-int64.yaml;
        };
      }
      inputs.catppuccin-trivial.nixosModules.catppuccin
      {
        catppuccin = {
          enable = true;
          flavor = "mocha";
          accent = "rosewater";
        };
      }
      inputs.nix-vscode-server-trivial.nixosModules.default
      {
        services.vscode-server.enable = true;
      }

      ../../../../modules/nixos
      ../../../../modules/cross
      {
        nixos = {
          gnome.enable = true;
          amd.enable = true;
        };
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
