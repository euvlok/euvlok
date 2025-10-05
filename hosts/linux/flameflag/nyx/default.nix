{ inputs, ... }:
{
  nyx = inputs.nixpkgs-flameflag.lib.nixosSystem {
    specialArgs = { inherit inputs; };
    modules = [
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
