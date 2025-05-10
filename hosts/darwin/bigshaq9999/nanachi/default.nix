{inputs, ...}: {
  faputa = inputs.nix-darwin-donteatoreo.lib.darwinSystem {
    specialArgs = {inherit inputs;};
    modules = [
      ../../shared/system.nix
      # ./brew.nix
      ./configuration.nix
      ./home.nix
      ./system.nix
      ./zsh.nix

      ../../../../modules/cross
      {
        cross = {
          nix.enable = true;
          nixpkgs.enable = true;
        };
      }
    ];
  };
}
