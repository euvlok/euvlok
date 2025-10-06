{ inputs, ... }:
{
  unsigned-int8 = inputs.nix-darwin-ashuramaruzxc.lib.darwinSystem {
    specialArgs = { inherit inputs; };
    modules = [
      inputs.self.darwinModules
      ../../../hm/ashuramaruzxc/fonts.nix
      ./brew.nix
      ./configuration.nix
      ./home.nix
      ./system.nix
      { services.protonmail-bridge.enable = true; }
    ]
    ++ [
      inputs.self.crossModules
      {
        cross = {
          nix.enable = true;
          nixpkgs.enable = true;
        };
      }
    ];
  };
}
