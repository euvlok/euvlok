{ inputs, ... }:
let
  hostArgs = { inherit inputs; };
in
{
  flake = {
    nixosConfigurations = {
      unsigned-int16 = (import ../../hosts/linux/ashuramaruzxc/unsigned-int16 hostArgs).unsigned-int16;
      unsigned-int32 = (import ../../hosts/linux/ashuramaruzxc/unsigned-int32 hostArgs).unsigned-int32;
      unsigned-int64 = (import ../../hosts/linux/ashuramaruzxc/unsigned-int64 hostArgs).unsigned-int64;
    };
    darwinConfigurations = {
      unsigned-int8 = (import ../../hosts/darwin/ashuramaruzxc/unsigned-int8 hostArgs).unsigned-int8;
    };
    homeConfigurations.ashuramaruzxc = import ../../hosts/hm/ashuramaruzxc;
  };
}
