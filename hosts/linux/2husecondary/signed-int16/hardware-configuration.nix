{
  pkgs,
  lib,
  config,
  ...
}:
{
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  boot = {
    kernelPackages = pkgs.unstable.linuxPackages_xanmod;
    kernelModules = [
      # dkms
      "kvm-amd"
      "zenpower"
      "v4l2loopback" # scrcpy
      # lvm2
      "dm-cache"
      "dm-cache-smq"
      "dm-persistent-data"
      "dm-bio-prison"
      "dm-clone"
      "dm-crypt"
      "dm-writecache"
      "dm-mirror"
      "dm-snapshot"
    ];
    extraModulePackages = builtins.attrValues {
      inherit (config.boot.kernelPackages) zenpower v4l2loopback;
    };
    blacklistedKernelModules = [
      "i915"
      "amdgpu"
      "nouveau"
    ];
    supportedFilesystems = {
      btrfs = true;
      xfs = true;
      ntfs = true;
    };
  };
  boot.loader = {
    grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      useOSProber = true;
      configurationLimit = 15;
    };
    generationsDir.copyKernels = true;
    efi.canTouchEfiVariables = true;
    efi.efiSysMountPoint = "/boot";
    timeout = 30;
  };
  boot.plymouth.enable = true;
  ### ----------------BOOT------------------- ###
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/26EA-3BB2";
    fsType = "vfat";
  };
  ### ----------------BOOT------------------- ###
  boot.initrd = {
    availableKernelModules = [
      "nvme"
      "xhci_pci"
      "ahci"
      "usbhid"
      "usb_storage"
      "uas"
      "sd_mod"
    ];
    kernelModules = [
      # modules
      "vfat"
    ];
  };
  ### ---------------boot drive-------------------- ###
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/29bfb700-f152-42f9-ab82-7a3faa2d4cc5";
    fsType = "ext4";
    options = [
      "noatime"
    ];
  };
  ### ---------------boot drive-------------------- ###

  ### ---------------anything else-------------------- ###
  fileSystems."/mnt/big" = {
    device = "/dev/disk/by-uuid/74248E2A248DF002";
    fsType = "ntfs-3g";
    options = [
      "rw"
      "uid=1000"
    ];
  };
  fileSystems."/mnt/wiwi" = {
    device = "/dev/disk/by-uuid/E4467BA4467B75E0";
    fsType = "ntfs-3g";
    options = [
      "rw"
      "uid=1000"
    ];
  };
  ### ---------------anything else-------------------- ###

  swapDevices = [ { device = "/mnt/wiwi/swapfile"; } ];

  hardware = {
    enableRedistributableFirmware = true;
    firmware = builtins.attrValues { inherit (pkgs) linux-firmware; };
  };
  services.fstrim = {
    enable = true;
    interval = "weekly";
  };
  services.fwupd.enable = true;
  system.fsPackages = [ pkgs.sshfs ];
  environment.systemPackages = [ pkgs.cifs-utils ];
}
