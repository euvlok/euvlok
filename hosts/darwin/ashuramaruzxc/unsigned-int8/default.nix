{ inputs, ... }:
{
  unsigned-int8 = inputs.nix-darwin-ashuramaruzxc.lib.darwinSystem {
    specialArgs = { inherit inputs; };
    modules = [
      inputs.self.darwinModules.default
      ../../../linux/ashuramaruzxc/shared/system/fonts.nix
      ./brew.nix
      ./configuration.nix
      ./home.nix
      ./system.nix
    ];
  };
}
