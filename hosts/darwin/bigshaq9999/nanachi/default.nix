{ inputs, ... }:
{
  faputa = inputs.nix-darwin-bigshaq9999.lib.darwinSystem {
    specialArgs = { inherit inputs; };
    modules = [
      ../../shared/system.nix
      ./configuration.nix
      ./home.nix
      ./system.nix
      ./zsh.nix

      ../../../../modules/cross
      {
        cross = {
          nix.enable = true;
          nixpkgs.enable = true;
        };
      }
    ];
  };
}
