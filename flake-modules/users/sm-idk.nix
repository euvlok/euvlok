{ inputs, ... }:
{
  euvlok.users.sm-idk = {
    nixosHosts = {
      laptop.configuration = inputs.sm-idk-null.nixosConfigurations.laptop;
      ledatel.configuration = inputs.sm-idk-null.nixosConfigurations.ledatel;
      "null".configuration = inputs.sm-idk-null.nixosConfigurations."null";
      zero.configuration = inputs.sm-idk-null.nixosConfigurations.zero;
    };
    homeConfigurations.sm-idk = import ../../hosts/hm/sm-idk;
  };
}
