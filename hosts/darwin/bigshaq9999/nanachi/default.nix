{ inputs, ... }:
{
  faputa = inputs.nix-darwin-bigshaq9999.lib.darwinSystem {
    specialArgs = { inherit inputs; };
    modules = [
      ../../../../modules/darwin
      ./configuration.nix
      ./home.nix
      ./system.nix
      ./fonts.nix
    ]
    ++ [
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
