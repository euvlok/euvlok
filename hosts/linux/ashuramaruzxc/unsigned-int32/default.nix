{ inputs, ... }:
{
  unsigned-int32 = inputs.nixpkgs-ashuramaruzxc.lib.nixosSystem {
    specialArgs = { inherit inputs; };
    modules = [
      ./configuration.nix
      ./home.nix
      inputs.sops-nix.nixosModules.sops
      {
        sops = {
          age.keyFile = "/var/lib/sops/age/keys.txt";
          defaultSopsFile = ../../../../secrets/ashuramaruzxc_unsigned-int32.yaml;
        };
      }
      inputs.anime-game-launcher-ashuramaruzxc.nixosModules.default
      inputs.catppuccin.nixosModules.catppuccin
      {
        catppuccin = {
          enable = true;
          flavor = "mocha";
          accent = "rosewater";
        };
      }
      ../../../../modules/nixos
      ../../../../modules/cross
      {
        nixos = {
          gnome.enable = true;
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
    ];
  };
}
