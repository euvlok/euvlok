{ inputs, ... }:
{
  nanachi = inputs.nixpkgs-bigshaq9999.lib.nixosSystem {
    specialArgs = { inherit inputs; };
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
    ];
  };
}
