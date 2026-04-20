{ inputs, ... }:
{
  flake = {
    nixosConfigurations.nanachi = import ../../hosts/linux/bigshaq9999/nanachi inputs;
    darwinConfigurations.faputa = import ../../hosts/darwin/bigshaq9999/nanachi inputs;
    homeConfigurations.bigshaq9999 = import ../../hosts/hm/bigshaq9999;
  };
}
