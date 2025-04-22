{ inputs, ... }:
{
  unsigned-int8 = inputs.nix-darwin-ashuramaruzxc.lib.darwinSystem {
    specialArgs = { inherit inputs; };
    modules = [
      ../../shared
      ./brew.nix
      ./configuration.nix
      ./home.nix

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
