inputs:
inputs.nix-darwin.lib.darwinSystem {
  specialArgs = { inherit inputs; };
  modules = [
    inputs.self.darwinModules.default
    ./configuration.nix
    ./fonts.nix
    ./launchd.nix
    ./packages.nix
    ./system.nix
  ];
}
