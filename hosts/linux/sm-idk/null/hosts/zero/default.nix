{ inputs, ... }:
{
  zero = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit inputs; };
    system = "aarch64-linux";
    modules = [ ./configuration.nix ];
  };
}
