{ inputs, ... }:
{
  faputa = inputs.nix-darwin.lib.darwinSystem {
    specialArgs = { inherit inputs; };
    modules = [
      inputs.self.darwinModules.default
      ./configuration.nix
      ./home.nix
      ./system.nix
      ./fonts.nix
      ./brew.nix
      { services.tailscale.enable = true; }
    ];
  };
}
