{
  pkgs,
  lib,
  config,
  ...
}:
{
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  boot = {
    kernelPackages = pkgs.unstable.linuxPackages_xanmod_latest;
    kernelModules = [
      # dkms
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
      "hid_apple"
    ];
    extraModulePackages = builtins.attrValues {
      inherit (config.boot.kernelPackages) v4l2loopback;
    };
    extraModprobeConfig = ''
      options hid_apple fnmode=2
    '';
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

      # memtest
      memtest86.enable = true;
      memtest86.params = [
        "console=ttyS0,115200n8"
        "maxcpus=32"
      ];
    };
    generationsDir.copyKernels = true;
    efi.canTouchEfiVariables = true;
    efi.efiSysMountPoint = "/boot";
    timeout = 30;
  };
  # boot.plymouth.enable = true;
  ### ----------------BOOT------------------- ###
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/12CE-A600";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };
  ### ----------------BOOT------------------- ###

  boot.initrd = {
    ### ---------------------LUKS--------------------- ###
    luks = {
      yubikeySupport = true;
      mitigateDMAAttacks = true;
      devices = {
        "root" = {
          device = "/dev/disk/by-uuid/5c64c922-ed1d-4c90-b926-39bc58340188";
          allowDiscards = true;
          bypassWorkqueues = true;
          yubikey = {
            slot = 2;
            twoFactor = true;
            gracePeriod = 5;
            keyLength = 64;
            saltLength = 16;
            storage = {
              device = "${config.fileSystems."/boot".device}";
              fsType = "vfat";
              path = "/crypt-storage/root_keyslot1";
            };
          };
        };
        "hddpool0" = {
          device = "/dev/md/hddpool0";
          yubikey = {
            slot = 2;
            twoFactor = true;
            gracePeriod = 5;
            keyLength = 64;
            saltLength = 16;
            storage = {
              device = "${config.fileSystems."/boot".device}";
              fsType = "vfat";
              path = "/crypt-storage/hddpool0_keyslot1";
            };
          };
        };
      };
    };
    ### ---------------------LUKS--------------------- ###

    network.enable = true;
    availableKernelModules = [
      "nvme"
      "thunderbolt"
      "xhci_pci"
      "ahci"
      "usbhid"
      "usb_storage"
      "uas"
      "sd_mod"
      # network
      "igc"
      "atlantic"
    ];
    kernelModules = [
      # modules
      "vfat"
      # yubico
      "nls_cp437"
      "nls_iso8859-1"
      # lvm2
      "dm-snapshot"
      "dm-cache"
      "dm-cache-smq"
      "dm-cache-mq"
      "dm-cache-cleaner"
    ];
    supportedFilesystems = config.boot.supportedFilesystems;
  };
  ### ---------------/dev/sdc2-------------------- ###
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/250b370c-a699-424c-a89b-3ad7869b7b4e";
    fsType = "btrfs";
    options = [
      "noatime"
      "autodefrag"
      "subvol=root"
      "space_cache=v2"
      "compress=zstd"
    ];
  };
  fileSystems."/var" = {
    device = "/dev/disk/by-uuid/250b370c-a699-424c-a89b-3ad7869b7b4e";
    fsType = "btrfs";
    options = [
      "noatime"
      "autodefrag"
      "subvol=var"
      "space_cache=v2"
      "compress=zstd"
    ];
    neededForBoot = true;
  };
  fileSystems."/var/log" = {
    device = "/dev/disk/by-uuid/250b370c-a699-424c-a89b-3ad7869b7b4e";
    fsType = "btrfs";
    options = [
      "noatime"
      "autodefrag"
      "subvol=log"
      "space_cache=v2"
      "compress=zstd"
    ];
    neededForBoot = true;
  };
  fileSystems."/var/cache" = {
    device = "/dev/disk/by-uuid/250b370c-a699-424c-a89b-3ad7869b7b4e";
    fsType = "btrfs";
    options = [
      "noatime"
      "autodefrag"
      "subvol=cache"
      "space_cache=v2"
      "compress=zstd"
    ];
    neededForBoot = true;
  };
  fileSystems."/var/lib/machines" = {
    device = "/dev/disk/by-uuid/250b370c-a699-424c-a89b-3ad7869b7b4e";
    fsType = "btrfs";
    options = [
      "noatime"
      "autodefrag"
      "subvol=machines"
      "space_cache=v2"
      "compress=zstd"
    ];
    neededForBoot = true;
  };
  fileSystems."/var/lib/docker" = {
    device = "/dev/disk/by-uuid/250b370c-a699-424c-a89b-3ad7869b7b4e";
    fsType = "btrfs";
    options = [
      "noatime"
      "autodefrag"
      "subvol=docker"
      "space_cache=v2"
      "compress=zstd"
    ];
    neededForBoot = true;
  };
  fileSystems."/var/lib/sops" = {
    device = "/dev/disk/by-uuid/250b370c-a699-424c-a89b-3ad7869b7b4e";
    fsType = "btrfs";
    options = [
      "noatime"
      "autodefrag"
      "subvol=sops"
      "space_cache=v2"
      "compress=zstd"
    ];
    neededForBoot = true;
  };
  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/250b370c-a699-424c-a89b-3ad7869b7b4e";
    fsType = "btrfs";
    options = [
      "noatime"
      "subvol=nix"
      "autodefrag"
      "space_cache=v2"
      "compress=zstd"
    ];
  };
  fileSystems."/etc" = {
    device = "/dev/disk/by-uuid/250b370c-a699-424c-a89b-3ad7869b7b4e";
    fsType = "btrfs";
    options = [
      "noatime"
      "autodefrag"
      "subvol=etc"
      "space_cache=v2"
      "compress=zstd"
    ];
  };
  fileSystems."/Users" = {
    device = "/dev/disk/by-uuid/250b370c-a699-424c-a89b-3ad7869b7b4e";
    fsType = "btrfs";
    options = [
      "noatime"
      "autodefrag"
      "subvol=Users"
      "space_cache=v2"
      "compress=zstd"
    ];
  };
  fileSystems."/home/ashuramaru" = {
    device = "/Users/marie";
    options = [ "bind" ];
  };
  fileSystems."/home/meanrin" = {
    device = "/Users/alex";
    options = [ "bind" ];
  };
  ### ---------------/dev/sdc2-------------------- ###

  ### ---------------/dev/nvme2n1p1-------------------- ###
  fileSystems."/Shared/games" = {
    device = "/dev/disk/by-uuid/5053def6-e6f1-499f-93b2-d1d639644690";
    fsType = "ext4";
  };
  ### ---------------/dev/nvme2n1p1-------------------- ###

  ### ---------------/dev/md/hddpool0-------------------- ###
  fileSystems."/var/lib/backup/unsigned-int32" = {
    device = "/dev/hddpool0/backup";
    fsType = "btrfs";
    options = [
      "subvol=unsigned-int32"
      "noatime"
      "autodefrag"
      "compress=zstd"
    ];
  };
  fileSystems."/var/lib/backup/unsigned-int64" = {
    device = "/dev/hddpool0/backup";
    fsType = "btrfs";
    options = [
      "subvol=unsigned-int64"
      "noatime"
      "autodefrag"
      "compress=zstd"
    ];
  };
  fileSystems."/var/lib/backup/shared" = {
    device = "/dev/hddpool0/backup";
    fsType = "btrfs";
    options = [
      "subvol=shared"
      "noatime"
      "autodefrag"
      "compress=zstd"
    ];
  };
  fileSystems."/var/lib/backup/timemachine" = {
    device = "/dev/hddpool0/backup";
    fsType = "btrfs";
    options = [
      "subvol=timemachine"
      "noatime"
      "autodefrag"
      "compress=zstd"
    ];
  };
  fileSystems."/Shared/archive" = {
    device = "/dev/hddpool0/archive";
    fsType = "ext4";
    options = [
      "noatime"
      "nofail"
    ];
  };
  ### ---------------/dev/md/hddpool0-------------------- ###

  ### --------------- /dev/nvme0n1p3 --------------- ###
  fileSystems."/Shared/windows" = {
    device = "/dev/disk/by-uuid/468CC3228CC30B7F";
    fsType = "ntfs-3g";
    options = [
      "acl"
      "noatime"
      "discard"
      "nohidden"
      "sys_immutable"
      "windows_names"
      "uid=0"
      "gid=100"
    ];
  };
  ### --------------- /dev/nvme0n1p3 (windows) --------------- ###
  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
    fileSystems = [
      "/"
      "/var/lib/backup"
    ];
  };
  services.fstrim = {
    enable = true;
    interval = "weekly";
  };
  system.fsPackages = [ pkgs.sshfs ];
}
