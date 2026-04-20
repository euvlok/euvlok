{ inputs, ... }:
{
  flake = {
    nixosConfigurations.nyx = import ../../hosts/linux/flameflag/nyx inputs;
    darwinConfigurations.FlameFlags-Mac-mini = import ../../hosts/darwin/flameflag/flame inputs;
    homeConfigurations.flameflag = import ../../hosts/hm/flameflag;
  };
}
