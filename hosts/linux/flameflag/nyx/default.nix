inputs:
inputs.nixpkgs.lib.nixosSystem {
  specialArgs = { inherit inputs; };
  modules = [
    inputs.self.nixosModules.default
    ./configuration.nix
    ./packages.nix
    {
      nixos = {
        amd.enable = true;
        nvidia.enable = true;
        gnome.enable = true;
      };
    }
  ];
}
