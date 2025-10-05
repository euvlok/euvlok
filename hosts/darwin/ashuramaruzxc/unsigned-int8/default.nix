{ inputs, ... }:
{
  unsigned-int8 = inputs.nix-darwin-ashuramaruzxc.lib.darwinSystem {
    specialArgs = { inherit inputs; };
    modules = [
      ../../../../modules/darwin
      ../../../hm/ashuramaruzxc/fonts.nix
      ./brew.nix
      ./configuration.nix
      ./home.nix
      ./system.nix
      { services.protonmail-bridge.enable = true; }
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
