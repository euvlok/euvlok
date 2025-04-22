_: {
  networking = {
    networkmanager.enable = true;
    networkmanager.ensureProfiles.profiles = {
      ethernet = {
        connection = {
          id = "ethernet";
          type = "ethernet";
          master = "bond0";
          slave-type = "bond";
        };
        ipv4.method = "auto";
        ipv6.method = "auto";
      };
    };
  };
}
