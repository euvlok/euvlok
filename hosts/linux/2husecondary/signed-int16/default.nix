{ inputs, ... }:
{
  signed-int16 = inputs.nixpkgs-2husecondary.lib.nixosSystem {
    specialArgs = { inherit inputs; };
    modules = [
      inputs.self.nixosModules.default
      ./configuration.nix
      ./home.nix
      inputs.anime-game-launcher-source.nixosModules.default
      { programs.anime-game-launcher.enable = true; }
    ]
    ++ [
      inputs.sops-nix-trivial.nixosModules.sops
      {
        sops = {
          age.keyFile = "/var/lib/sops/age/keys.txt";
          defaultSopsFile = ../../../../secrets/2husecondary.yaml;
        };
      }
    ]
    ++ [
      inputs.catppuccin-trivial.nixosModules.catppuccin
      {
        catppuccin = {
          enable = true;
          flavor = "latte";
          accent = "sky";
        };
      }
    ]
    ++ [
      inputs.self.crossModules.default
      {
        nixos = {
          nvidia.enable = true;
          plasma.enable = true;
          steam.enable = true;
          zram.enable = true;
        };
      }
    ];
  };
}
