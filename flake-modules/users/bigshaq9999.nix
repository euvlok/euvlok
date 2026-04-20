{ inputs, ... }:
let
  hostArgs = { inherit inputs; };
in
{
  flake = {
    nixosConfigurations.nanachi = (import ../../hosts/linux/bigshaq9999/nanachi hostArgs).nanachi;
    darwinConfigurations.faputa = (import ../../hosts/darwin/bigshaq9999/nanachi hostArgs).faputa;
    homeConfigurations.bigshaq9999 = import ../../hosts/hm/bigshaq9999;
  };
}
