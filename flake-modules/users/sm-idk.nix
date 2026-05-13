{ ... }:
{
  euvlok.users.sm-idk = {
    nixosHosts = {
      laptop.path = ../../hosts/linux/sm-idk/null/hosts/laptop;
      ledatel.path = ../../hosts/linux/sm-idk/null/hosts/ledatel;
      "null".path = ../../hosts/linux/sm-idk/null/hosts/null;
      zero.path = ../../hosts/linux/sm-idk/null/hosts/zero;
    };
    homeConfigurations.sm-idk = import ../../hosts/hm/sm-idk;
  };
}
