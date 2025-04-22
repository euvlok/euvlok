{
  # inputs,
  lib,
  config,
  pkgs,
  modulesPath,
  ...
}:
let
  automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
in
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
  boot = {
    kernelPackages = pkgs.linuxPackages_xanmod;
    kernelModules = [
      # dkms
      "kvm-amd"
      "zenpower"
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
      inherit (config.boot.kernelPackages) zenpower;
    };
    supportedFilesystems = [ "xfs" ];
    swraid = {
      enable = true;
      mdadmConf = ''
        HOMEHOST <ignore>
        ARRAY /dev/md/nvmepool metadata=1.2 name=unsigned-int64:nvmepool UUID=1cc0cab9:41316762:e55c90b0:81b34798
        MAILADDR ashuramaru@tenjin-dk.com
        MAILFROM no-reply@cloud.tenjin-dk.com
      '';
    };
  };
  boot.loader = {
    systemd-boot = {
      enable = true;
      consoleMode = "max";
      netbootxyz.enable = true;
      configurationLimit = 30;
    };
    generationsDir.copyKernels = true;
    efi.canTouchEfiVariables = true;
    efi.efiSysMountPoint = "/boot";
    timeout = 10;
  };
  ### ----------------BOOT------------------- ###
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/83C1-3859";
    fsType = "vfat";
  };
  ### ----------------BOOT------------------- ###
  boot.initrd = {
    systemd.users.root.shell = "/bin/cryptsetup-askpass";
    network = {
      enable = true;
      ssh = {
        enable = true;
        port = 2222;
        hostKeys = [
          "/boot/crypt-storage/sshd/ssh_host_ed25519"
          "/boot/crypt-storage/sshd/ssh_host_rsa_key"
        ];
        authorizedKeys = lib.flatten [
          config.users.users.ashuramaru.openssh.authorizedKeys.keys
          config.users.users.fumono.openssh.authorizedKeys.keys
        ];
      };
    };
    luks = {
      yubikeySupport = true;
      reusePassphrases = true;
      mitigateDMAAttacks = true;
      devices = {
        "root" = {
          device = "/dev/disk/by-uuid/50007c28-d848-44bf-9057-aeee667e529f";
          allowDiscards = true;
          bypassWorkqueues = true;
        };
        "nvmepool" = {
          device = "/dev/md/nvmepool";
          allowDiscards = true;
          bypassWorkqueues = true;
        };
        "hddpool".device = "/dev/disk/by-uuid/b51b6d8a-eef4-4f4a-8886-068a582d6d0b";
      };
    };
    availableKernelModules = [
      "nvme"
      "xhci_pci"
      "ahci"
      "usbhid"
      "usb_storage"
      "uas"
      "sd_mod"
      "igb"
      # "igc" # No longer needed in initrd might get handy in a future, Intel 2.5gbe NIC
      # "ixgbe" # Intel 10gbe SFP+ NIC
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
  };
  ### ---------------/dev/sda2-------------------- ###
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/26953b02-1451-48a0-acdc-d02261ce95df";
    fsType = "btrfs";
    options = [
      "noatime"
      "autodefrag"
      "subvol=root"
      "space_cache=v2"
      "compress=zstd:1"
    ];
  };
  fileSystems."/var" = {
    device = "/dev/disk/by-uuid/26953b02-1451-48a0-acdc-d02261ce95df";
    fsType = "btrfs";
    options = [
      "noatime"
      "autodefrag"
      "subvol=var"
      "space_cache=v2"
      "compress=zstd:1"
    ];
    neededForBoot = true;
  };
  fileSystems."/var/log" = {
    device = "/dev/disk/by-uuid/26953b02-1451-48a0-acdc-d02261ce95df";
    fsType = "btrfs";
    options = [
      "noatime"
      "autodefrag"
      "subvol=log"
      "space_cache=v2"
      "compress=zstd:1"
    ];
    neededForBoot = true;
  };
  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/26953b02-1451-48a0-acdc-d02261ce95df";
    fsType = "btrfs";
    options = [
      "noatime"
      "subvol=nix"
      "autodefrag"
      "space_cache=v2"
      "compress=zstd:1"
    ];
  };
  fileSystems."/persist" = {
    device = "/dev/disk/by-uuid/26953b02-1451-48a0-acdc-d02261ce95df";
    fsType = "btrfs";
    options = [
      "noatime"
      "autodefrag"
      "subvol=persist"
      "space_cache=v2"
      "compress=zstd:1"
    ];
  };
  fileSystems."/Users" = {
    device = "/dev/disk/by-uuid/26953b02-1451-48a0-acdc-d02261ce95df";
    fsType = "btrfs";
    options = [
      "noatime"
      "autodefrag"
      "subvol=Users"
      "space_cache=v2"
      "compress=zstd:1"
    ];
  };
  ### ---------------/dev/sda2-------------------- ###

  ### ---------------/dev/md/nvmepool-------------------- ###
  fileSystems."/var/lib/nextcloud/data" = {
    device = "/dev/mapper/nvmepool";
    fsType = "btrfs";
    options = [
      "noatime"
      "autodefrag"
      "space_cache=v2"
      "subvol=nextcloud"
      "compress=zstd:1"
    ];
  };
  ### ---------------/dev/md/nvmepool-------------------- ###

  ### ---------------/dev/md/nvmepool-------------------- ###

  ### ---------------/dev/hddpool-------------------- ###
  fileSystems."/var/lib/backup" = {
    device = "/dev/disk/by-uuid/09957dc9-4764-44cb-99b4-fed2ce553b27";
    fsType = "ext4";
    options = [
      "nofail"
      "noatime"
      "data=ordered"
    ];
  };
  fileSystems."/var/lib/transmission" = {
    device = "/dev/disk/by-uuid/949251e4-d899-42ee-805f-b888db84d657";
    fsType = "ext4";
    options = [
      "nofail"
      "noatime"
      "data=ordered"
    ];
  };
  fileSystems."/mnt/media" = {
    device = "/dev/disk/by-uuid/1af5032e-a4c4-472b-8e0f-7ef5e8b2e5f6";
    fsType = "ext4";
    options = [
      "nofail"
      "noatime"
      "data=ordered"
    ];
  };
  ### ---------------/dev/hddpool-------------------- ###

  ### ---------------SMB/NAS/CIFS-------------------- ###
  ### ---------------backups-------------------- ###
  ### ---------------media-------------------- ###
  # fileSystems."/mnt/media" = {
  #   device = "//u369008-sub9.your-storagebox.de/u369008-sub9";
  #   fsType = "cifs";
  #   options = [
  #     "${automount_opts},credentials=/root/secrets/storagebox/u369008-sub9,uid=991,gid=981,dir_mode=0777,file_mode=0777"
  #   ];
  # };
  # fileSystems."/var/lib/transmission/private" = {
  #   device = "//u369008-sub10.your-storagebox.de/u369008-sub10";
  #   fsType = "cifs";
  #   options = [
  #     "${automount_opts},credentials=/root/secrets/storagebox/u369008-sub10,uid=70,gid=70,dir_mode=0777,file_mode=0777"
  #   ];
  # };
  # fileSystems."/var/lib/transmission/public" = {
  #   device = "//u369008-sub11.your-storagebox.de/u369008-sub11";
  #   fsType = "cifs";
  #   options = [
  #     "${automount_opts},credentials=/root/secrets/storagebox/u369008-sub11,uid=70,gid=70,dir_mode=0777,file_mode=0777"
  #   ];
  # };
  ### ---------------SMB/NAS/CIFS-------------------- ###
  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
    fileSystems = [ "/" ];
  };
  services.fstrim = {
    enable = true;
    interval = "weekly";
  };
  system.fsPackages = [ pkgs.sshfs ];
  environment.systemPackages = [ pkgs.cifs-utils ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
