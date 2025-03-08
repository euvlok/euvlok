{ inputs, ... }:
{
  nanachi = inputs.nixpkgs-bigshaq9999.lib.nixosSystem {
    specialArgs = { inherit inputs; };
    modules = [
      ./configuration.nix
      ./home.nix
      inputs.catppuccin.nixosModules.catppuccin

      ../../../../modules/nixos
      ../../../../modules/cross
      {
        cross = {
          nix.enable = true;
          nixpkgs.enable = true;
          nixpkgs.allowUnfree = true;
        };
      }
    ];
  };
}
