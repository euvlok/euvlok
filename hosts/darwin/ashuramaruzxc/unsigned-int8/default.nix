inputs:
inputs.nix-darwin.lib.darwinSystem {
  specialArgs = { inherit inputs; };
  modules = [
    inputs.self.darwinModules.default
    ../../../../modules/darwin/zsh.nix
    ./brew.nix
    ./configuration.nix
    ./home.nix
    ./system.nix
    inputs.nix-homebrew-trivial.darwinModules.nix-homebrew
    {
      nix-homebrew = {
        enable = true;
        user = "ashuramaru";
        taps = {
          "homebrew/homebrew-core" = inputs.homebrew-core-trivial;
          "homebrew/homebrew-cask" = inputs.homebrew-cask-trivial;
          "cfergeau/homebrew-crc" = inputs.homebrew-crc-trivial;
        };
        autoMigrate = true;
      };
    }
  ];
}
