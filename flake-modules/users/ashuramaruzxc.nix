{
  euvlok.users.ashuramaruzxc = {
    nixosHosts = {
      unsigned-int16.path = ../../hosts/linux/ashuramaruzxc/unsigned-int16;
      unsigned-int32.path = ../../hosts/linux/ashuramaruzxc/unsigned-int32;
      unsigned-int64.path = ../../hosts/linux/ashuramaruzxc/unsigned-int64;
    };
    darwinHosts.unsigned-int8.path = ../../hosts/darwin/ashuramaruzxc/unsigned-int8;
    homeConfigurations.ashuramaruzxc = import ../../hosts/hm/ashuramaruzxc;
  };
}
