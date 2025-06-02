{ inputs, ... }:
{
  anons-Mac-mini = inputs.nix-darwin-donteatoreo.lib.darwinSystem {
    specialArgs = { inherit inputs; };
    modules = [
      ../../../../modules/darwin
      ./configuration.nix
      ./fonts.nix
      ./home.nix
      ./system.nix

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
