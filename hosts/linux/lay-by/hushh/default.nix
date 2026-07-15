inputs:
inputs.nixpkgs.lib.nixosSystem {
  specialArgs = { inherit inputs; };
  modules = [
    inputs.self.nixosModules.default
    ./configuration.nix
    ./home.nix
    {
      euvlok.nixpkgs.unstableSource = inputs.nixpkgs-unstable;
      nixos = {
        gui.enable = true;
        nvidia.enable = true;
        steam.enable = true;
      };
    }
  ];
}
