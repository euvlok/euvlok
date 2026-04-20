inputs:
inputs.nix-darwin.lib.darwinSystem {
  specialArgs = { inherit inputs; };
  modules = [
    inputs.self.darwinModules.default
    ../../../../modules/darwin/zsh.nix
    ./configuration.nix
    ./home.nix
    ./system.nix
    ./fonts.nix
    ./brew.nix
    { services.tailscale.enable = true; }
  ];
}
