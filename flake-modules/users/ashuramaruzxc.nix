{ inputs, ... }:
{
  flake = {
    nixosConfigurations = {
      unsigned-int16 = import ../../hosts/linux/ashuramaruzxc/unsigned-int16 inputs;
      unsigned-int32 = import ../../hosts/linux/ashuramaruzxc/unsigned-int32 inputs;
      unsigned-int64 = import ../../hosts/linux/ashuramaruzxc/unsigned-int64 inputs;
    };
    darwinConfigurations = {
      unsigned-int8 = import ../../hosts/darwin/ashuramaruzxc/unsigned-int8 inputs;
    };
    homeConfigurations.ashuramaruzxc = import ../../hosts/hm/ashuramaruzxc;
  };
}
