{
  pkgs,
  lib,
  config,
  ...
}:
{
  imports = [
    {
      fileSystems =
        lib.attrsets.mapAttrs
          (
            mount: subvolume:
            {
              device = "/dev/mapper/root";
              fsType = "btrfs";
              options = [
                "noatime"
                "autodefrag"
                "subvol=${subvolume}"
                "space_cache=v2"
                "compress=zstd"
              ];
            }
            // lib.attrsets.optionalAttrs (lib.strings.hasPrefix "/var" mount) {
              neededForBoot = true;
            }
          )
          {
            "/" = "root";
            "/var" = "var";
            "/var/log" = "log";
            "/var/cache" = "cache";
            "/var/lib/machines" = "machines";
            "/var/lib/docker" = "docker";
            "/var/lib/sops" = "sops";
            "/etc" = "etc";
            "/Users" = "Users";
          };
    }
  ];

  nixpkgs.hostPlatform = lib.modules.mkDefault "x86_64-linux";

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernel.sysctl = {
      "kernel.nmi_watchdog" = 1;
      "vm.compaction_proactiveness" = 20;
      "vm.defrag_mode" = 1;
      "vm.dirty_background_bytes" = 536870912;
      "vm.dirty_bytes" = 4294967296;
      "vm.min_free_kbytes" = 1048576;
      "vm.vfs_cache_pressure" = 50;
      "vm.watermark_scale_factor" = 100;
    };
    kernelModules = [
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
      # misc
      "hid_apple"
      "hid_playstation" # for some reason dualsense acts as a mouse if it's not loaded early on
      "v4l2loopback" # scrcpy
    ];
    extraModulePackages = lib.attrsets.attrValues {
      inherit (config.boot.kernelPackages) zenpower v4l2loopback;
    };
    kernelParams = [
      ### ------------------------------------ ###
      # if thunderbolt turned off
      # "ip=192.168.1.100::192.168.1.1:255.255.255.0::enp5s0:dhcp"
      # "ip=192.168.1.110::192.168.1.1:255.255.255.0::enp7s0:dhcp"
      # if thunerbolt turned on
      # "ip=192.168.1.100::192.168.1.1:255.255.255.0::enp57s0:dhcp"
      # "ip=192.168.1.110::192.168.1.1:255.255.255.0::enp59s0:dhcp"
      ### ------------------------------------ ###
      "video=DP-1:2560x1440@120"
      "video=DP-2:2560x1440@120"
      "video=DP-3:2560x1440@120"
      "video=DP-4:2560x1440@120"
      "video=HDMI1:2560x1440@120"
      ### ------------------------------------ ###
      "iommu=pt"
      "amd_pstate=active"
      ### ------------------------------------ ###
      "transparent_hugepage=always"
      "thp_anon=16K:always;2M:always"
      ### ------------------------------------ ###
      "pcie_aspm=default"
    ];
    extraModprobeConfig = ''
      options hid_apple fnmode=2
    '';
    swraid = {
      enable = true;
      mdadmConf = ''
        HOMEHOST <ignore>
        ARRAY /dev/md/hddpool0 metadata=1.2 name=unsgined-int32:hddpool0 UUID=fe0631c5:f6957b40:6b696546:015251d0
        MAILADDR ashuramaru@tenjin-dk.com
        MAILFROM no-reply@cloud.tenjin-dk.com
      '';
    };
    # Blacklisted Kernel modules do not change
    blacklistedKernelModules = [
      "i915"
      "amdgpu"
      "nouveau"
      "k10temp"
    ];
    supportedFilesystems = {
      btrfs = true;
      xfs = true;
      ntfs = true;
    };
    binfmt.emulatedSystems = [ "aarch64-linux" ];
  };
  boot.loader = {
    limine = {
      enable = true;
      maxGenerations = 15;
      secureBoot.enable = true;
      validateChecksums = true;
      panicOnChecksumMismatch = true;
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
      mitigateDMAAttacks = true;
      devices = {
        "root" = {
          device = "/dev/disk/by-uuid/5c64c922-ed1d-4c90-b926-39bc58340188";
          allowDiscards = true;
          bypassWorkqueues = true;
          crypttabExtraOpts = [ "fido2-device=auto" ];
        };
        "hddpool0" = {
          device = "/dev/md/hddpool0";
          crypttabExtraOpts = [ "fido2-device=auto" ];
        };
      };
    };
    ### ---------------------LUKS--------------------- ###

    network.enable = true;
    availableKernelModules = [
      "xhci_pci"
      "thunderbolt"
      "nvme"
      "uas"
      "usb_storage"
      "usbhid"
      "sd_mod"
      "ahci"
      # network
      "atlantic"
      "igc"
    ];
    kernelModules = [
      # modules
      "vfat"
      # vfat filename encodings
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
  fileSystems."/nix" = {
    device = "/dev/mapper/root";
    fsType = "btrfs";
    options = [
      "noatime"
      "subvol=nix"
      "autodefrag"
      "space_cache=v2"
      "compress=zstd"
    ];
  };
  fileSystems."/home/ashuramaru" = {
    device = "/Users/marie";
    fsType = "none";
    options = [ "bind" ];
  };
  fileSystems."/home/meanrin" = {
    device = "/Users/alex";
    fsType = "none";
    options = [ "bind" ];
  };
  ### ---------------/dev/sdc2-------------------- ###

  ### ---------------/dev/nvme2n1p1-------------------- ###
  fileSystems."/Shared/games" = {
    device = "/dev/disk/by-uuid/5053def6-e6f1-499f-93b2-d1d639644690";
    fsType = "ext4";
    options = [ "noatime" ];
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
  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
    fileSystems = [
      "/"
      "/var/lib/backup"
    ];
  };
  system.fsPackages = [ pkgs.sshfs ];
}
