{ inputs, ... }:
{
  bigshaq9999 = inputs.nix-darwin-donteatoreo.lib.darwinSystem {
    specialArgs = { inherit inputs; };
    modules = [
      ../../shared/system.nix
      ./brew.nix
      ./configuration.nix
      ./home.nix
      ./system.nix
      ./zsh.nix

      ../../shared/protonmail-bridge.nix
      {
        services.protonmail-bridge.enable = true;
      }
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
