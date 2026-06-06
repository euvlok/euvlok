inputs:
inputs.nix-darwin.lib.darwinSystem {
  specialArgs = { inherit inputs; };
  modules = [
    inputs.self.darwinModules.default
    ./configuration.nix
    ./fonts.nix
    ./http-fixture
    ./launchd.nix
    ./packages.nix
    ./system.nix
  ];
}
