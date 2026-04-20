{ inputs, ... }:
let
  hostArgs = { inherit inputs; };
in
{
  flake = {
    nixosConfigurations."null" = (import ../../hosts/linux/sm-idk/null hostArgs).null;
    homeConfigurations.sm-idk = import ../../hosts/hm/sm-idk;
  };
}
