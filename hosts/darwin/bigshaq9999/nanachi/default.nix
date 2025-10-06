{ inputs, ... }:
{
  faputa = inputs.nix-darwin-bigshaq9999.lib.darwinSystem {
    specialArgs = { inherit inputs; };
    modules = [
      inputs.self.darwinModules
      inputs.self.crossModules
      ./configuration.nix
      ./home.nix
      ./system.nix
      ./fonts.nix
    ];
  };
}
