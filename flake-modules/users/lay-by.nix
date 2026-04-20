{ inputs, ... }:
{
  flake = {
    nixosConfigurations.blind-faith = import ../../hosts/linux/lay-by/hushh inputs;
    homeConfigurations.lay-by = import ../../hosts/hm/lay-by;
  };
}
