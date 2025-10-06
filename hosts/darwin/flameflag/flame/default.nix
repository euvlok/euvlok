{ inputs, ... }:
{
  FlameFlags-Mac-mini = inputs.nix-darwin-flameflag.lib.darwinSystem {
    specialArgs = { inherit inputs; };
    modules = [
      inputs.self.darwinModules
      inputs.self.crossModules
      ./configuration.nix
      ./fonts.nix
      ./home.nix
      ./system.nix
    ];
  };
}
