{
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
        ARRAY /dev/md10 metadata=1.2 name=unsigned-int64:fpool UUID=bb2e96e5:c781e2d1:ead32a7f:e7051656
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
    device = "/dev/disk/by-uuid/9C71-246F";
    fsType = "vfat";
  };
  ### ----------------BOOT------------------- ###
  boot.initrd = {
    network = {
      enable = true;
      ssh = {
        enable = true;
        port = 2222;
        hostKeys =
          let
            pathToSecrets = "/root/secrets/sshd";
          in
          [
            "${pathToSecrets}/ssh_host_ed25519"
            "${pathToSecrets}/ssh_host_ecdsa"
            "${pathToSecrets}/ssh_host_rsa_key"
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
          device = "/dev/disk/by-uuid/5126dd32-509c-4946-b421-1a860c843abd";
          allowDiscards = true;
          bypassWorkqueues = true;
        };
        "fpool" = {
          device = "/dev/md10";
          allowDiscards = true;
          bypassWorkqueues = true;
        };
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
      "ixgbe" # Intel 10gbe SFP+ NIC
      # "igc" No longer needed in initrd might get handy in a future, Intel 2.5gbe NIC
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
  ### ---------------/dev/nvme0n1p2-------------------- ###
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/71e6bf9d-3edd-4ef0-a0fd-f7174c136eb3";
    fsType = "btrfs";
    options = [
      "subvol=/root"
      "noatime"
      "compress-force=zstd:9"
      "ssd"
      "discard=async"
      "space_cache=v2"
    ];
  };
  fileSystems."/var" = {
    device = "/dev/disk/by-uuid/71e6bf9d-3edd-4ef0-a0fd-f7174c136eb3";
    fsType = "btrfs";
    options = [
      "subvol=/var"
      "noatime"
      "compress-force=zstd:9"
      "ssd"
      "discard=async"
      "space_cache=v2"
    ];
  };
  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/71e6bf9d-3edd-4ef0-a0fd-f7174c136eb3";
    fsType = "btrfs";
    options = [
      "subvol=/nix"
      "noatime"
      "compress-force=zstd:9"
      "ssd"
      "discard=async"
      "space_cache=v2"
    ];
  };
  fileSystems."/Users" = {
    device = "/dev/disk/by-uuid/71e6bf9d-3edd-4ef0-a0fd-f7174c136eb3";
    fsType = "btrfs";
    options = [
      "subvol=/Users"
      "noatime"
      "compress-force=zstd:9"
      "ssd"
      "discard=async"
      "space_cache=v2"
    ];
  };
  ### ---------------/dev/nvme0n1p2-------------------- ###
  fileSystems."/var/lib/nextcloud/data" = {
    device = "/dev/disk/by-uuid/d7aca109-b520-4052-9844-39a4378a1bac";
    fsType = "btrfs";
    options = [
      "subvol=/nextcloud"
      "noatime"
      "compress-force=zstd:9"
      "ssd"
      "discard=async"
      "space_cache=v2"
    ];
  };
  ### ---------------SMB/NAS/CIFS-------------------- ###
  ### ---------------backups-------------------- ###
  ### ---------------media-------------------- ###
  fileSystems."/mnt/media" = {
    device = "//u369008-sub9.your-storagebox.de/u369008-sub9";
    fsType = "cifs";
    options = [
      "${automount_opts},credentials=/root/secrets/storagebox/u369008-sub9,uid=991,gid=981,dir_mode=0777,file_mode=0777"
    ];
  };
  fileSystems."/var/lib/transmission/private" = {
    device = "//u369008-sub10.your-storagebox.de/u369008-sub10";
    fsType = "cifs";
    options = [
      "${automount_opts},credentials=/root/secrets/storagebox/u369008-sub10,uid=70,gid=70,dir_mode=0777,file_mode=0777"
    ];
  };
  fileSystems."/var/lib/transmission/public" = {
    device = "//u369008-sub11.your-storagebox.de/u369008-sub11";
    fsType = "cifs";
    options = [
      "${automount_opts},credentials=/root/secrets/storagebox/u369008-sub11,uid=70,gid=70,dir_mode=0777,file_mode=0777"
    ];
  };
  ### ---------------SMB/NAS/CIFS-------------------- ###
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
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
