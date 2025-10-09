{ inputs, ... }:
{
  nyx = inputs.nixpkgs-flameflag.lib.nixosSystem {
    specialArgs = { inherit inputs; };
    modules = [
      inputs.self.nixosModules.default
      ./configuration.nix
      ./home.nix
    ]
    ++ [
      inputs.catppuccin-trivial.nixosModules.catppuccin
      {
        catppuccin = {
          enable = true;
          flavor = "frappe";
          accent = "blue";
        };
      }
    ]
    ++ [
      inputs.self.crossModules.default
      {
        nixos = {
          amd.enable = true;
          nvidia.enable = true;
          gnome.enable = true;
        };
      }
    ];
  };
}
