{ inputs, ... }:
{
  unsigned-int32 = inputs.nixpkgs-ashuramaruzxc.lib.nixosSystem {
    specialArgs = { inherit inputs; };
    modules = [
      ./configuration.nix
      ./home.nix
      inputs.anime-game-launcher.nixosModules.default
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
        nixos.nvidia.enable = true;
        cross = {
          nix.enable = true;
          nixpkgs = {
            enable = true;
            allowUnfree = true;
            cudaSupport = true;
          };
        };
      }
    ];
  };
}
