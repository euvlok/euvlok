{ lib, pkgs, ... }:
{
  hardware = {
    enableRedistributableFirmware = true;
    firmware = lib.attrsets.attrValues { inherit (pkgs) linux-firmware; };
  };
  services.fwupd.enable = true;
}
