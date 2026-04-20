{ inputs, ... }:
let
  hostArgs = { inherit inputs; };
in
{
  flake = {
    nixosConfigurations.blind-faith = (import ../../hosts/linux/lay-by/hushh hostArgs).blind-faith;
    homeConfigurations.lay-by = import ../../hosts/hm/lay-by;
  };
}
