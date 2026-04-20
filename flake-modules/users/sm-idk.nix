{ inputs, ... }:
{
  flake = {
    nixosConfigurations."null" = import ../../hosts/linux/sm-idk/null inputs;
    homeConfigurations.sm-idk = import ../../hosts/hm/sm-idk;
  };
}
