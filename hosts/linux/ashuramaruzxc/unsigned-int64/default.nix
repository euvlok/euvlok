{ inputs, ... }:
let
  inherit (import ../../../../lib/catppuccin.nix) mkCatppuccin hosts;
in
{
  unsigned-int64 = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit inputs; };
    modules = [
      inputs.self.nixosModules.default
      ./configuration.nix
      ./home.nix
      { sops.defaultSopsFile = ../../../../secrets/ashuramaruzxc_unsigned-int64.yaml; }
      (mkCatppuccin hosts.unsigned-int64)
      {
        nixos = {
          gnome.enable = true;
          amd.enable = true;
        };
      }
    ];
  };
}
