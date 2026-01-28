{ inputs, ... }:
let
  inherit (import ../shared/host-lib.nix { inherit inputs; }) mkHostSystem;
in
{
  unsigned-int64 = mkHostSystem {
    modules = [
      inputs.self.nixosModules.default
      ./configuration.nix
      ./home.nix
    ];
    sopsFile = ../../../../secrets/ashuramaruzxc_unsigned-int64.yaml;
    catppuccinAccent = "rosewater";
    extraModules = [
      {
        nixos = {
          gnome.enable = true;
          amd.enable = true;
        };
      }
    ];
  };
}
