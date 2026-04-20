{ inputs, ... }:
let
  hostArgs = { inherit inputs; };
in
{
  flake = {
    nixosConfigurations.nyx = (import ../../hosts/linux/flameflag/nyx hostArgs).nyx;
    darwinConfigurations.FlameFlags-Mac-mini =
      (import ../../hosts/darwin/flameflag/flame hostArgs).FlameFlags-Mac-mini;
    homeConfigurations.flameflag = import ../../hosts/hm/flameflag;
  };
}
