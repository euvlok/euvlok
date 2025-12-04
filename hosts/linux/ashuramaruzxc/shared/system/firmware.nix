{ pkgs, ... }:
{
  hardware = {
    enableRedistributableFirmware = true;
    firmware = builtins.attrValues { inherit (pkgs) linux-firmware; };
  };
  services.fwupd.enable = true;
}
