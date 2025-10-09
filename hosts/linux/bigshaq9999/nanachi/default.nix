{ inputs, ... }:
{
  nanachi = inputs.nixpkgs-bigshaq9999.lib.nixosSystem {
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
        nixos.gnome.enable = true;
        cross = {
          nix.enable = true;
          nixpkgs.enable = true;
        };
      }
    ];
  };
}
