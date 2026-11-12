{
  config,
  lib,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usb_storage"
    "sd_mod"
  ];
  boot.kernelModules = [ "kvm-amd" ];

  # Retained from the original installation, not a repartitioning recipe
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/2bd12814-cf56-461e-ba63-622337b5cd52";
    fsType = "ext4";
  };

  boot.initrd.luks.devices."luks-eebbd6d2-dd7f-42ae-98b5-03c6f4f65598".device =
    "/dev/disk/by-uuid/eebbd6d2-dd7f-42ae-98b5-03c6f4f65598";

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/6C45-D370";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/1c98642c-2bb8-4131-8d97-748c650a06fd"; }
    { device = "/var/lib/swapfile"; }
  ];

  nixpkgs.hostPlatform = lib.modules.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.modules.mkDefault config.hardware.enableRedistributableFirmware;
}
