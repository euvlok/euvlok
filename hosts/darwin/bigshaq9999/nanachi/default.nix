{ inputs, euvlok, ... }:
{
  faputa = inputs.nix-darwin-bigshaq9999.lib.darwinSystem {
    specialArgs = { inherit inputs euvlok; };
    modules = [
      ../../../../modules/darwin
      ./configuration.nix
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
