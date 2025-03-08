{
  pkgs,
  lib,
  config,
  ...
}:
{
  hardware = {
    enableRedistributableFirmware = true;
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    firmware = builtins.attrValues { inherit (pkgs) linux-firmware; };
  };
  services.fwupd.enable = true;
}
