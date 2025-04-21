{ inputs, ... }:
{
  nyx = inputs.nixpkgs-donteatoreo.lib.nixosSystem {
    specialArgs = { inherit inputs; };
    modules = [
      ../../shared/configuration.nix
      ./configuration.nix
      ./home.nix
      inputs.catppuccin.nixosModules.catppuccin
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
    ];
  };
}
