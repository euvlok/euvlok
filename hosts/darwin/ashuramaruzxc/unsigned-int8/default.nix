{ inputs, ... }:
{
  unsigned-int8 = inputs.nix-darwin-ashuramaruzxc.lib.darwinSystem {
    specialArgs = { inherit inputs; };
    modules = [
      inputs.self.darwinModules.default
      ../../../linux/ashuramaruzxc/shared/fonts.nix
      ./brew.nix
      ./configuration.nix
      ./home.nix
      ./system.nix
      { services.protonmail-bridge.enable = true; }
    ]
    ++ [
      inputs.self.crossModules.default
      {
        cross = {
          nix.enable = true;
          nixpkgs.enable = true;
        };
      }
    ];
  };
}
