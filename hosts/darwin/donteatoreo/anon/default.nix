{ inputs, ... }:
{
  anons-Mac-mini = inputs.nix-darwin-donteatoreo.lib.darwinSystem {
    specialArgs = { inherit inputs; };
    modules = [
      ../../shared/system.nix
      ./configuration.nix
      ./fonts.nix
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
