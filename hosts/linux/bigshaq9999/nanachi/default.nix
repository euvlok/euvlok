inputs:
let
  inherit (import ../../../../lib/catppuccin.nix) mkCatppuccin hosts;
in
inputs.nixpkgs.lib.nixosSystem {
  specialArgs = { inherit inputs; };
  modules = [
    inputs.self.nixosModules.default
    ./configuration.nix
    ./home.nix
    (mkCatppuccin hosts.nanachi-linux)
  ];
}
