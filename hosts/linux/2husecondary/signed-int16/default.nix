{ inputs, ... }:
{
  signed-int16 = inputs.nixpkgs-2husecondary.lib.nixosSystem {
    specialArgs = { inherit inputs; };
    modules = [
      ./configuration.nix
      ./home.nix
      inputs.sops-nix-trivial.nixosModules.sops
      {
        sops = {
          age.keyFile = "/var/lib/sops/age/keys.txt";
          defaultSopsFile = ../../../../secrets/2husecondary.yaml;
        };
      }
      inputs.catppuccin-trivial.nixosModules.catppuccin
      {
        catppuccin = {
          enable = true;
          flavor = "latte";
          accent = "sky";
        };
      }
      ../../../../modules/nixos
      ../../../../modules/cross
      {
        nixos = {
          nvidia.enable = true;
          plasma.enable = true;
          steam.enable = true;
          zram.enable = true;
        };
        cross = {
          nix.enable = true;
          nixpkgs = {
            enable = true;
            cudaSupport = true;
          };
        };
      }
      inputs.anime-game-launcher-source.nixosModules.default
      {
        programs.anime-game-launcher.enable = true;
      }
    ];
  };
}
