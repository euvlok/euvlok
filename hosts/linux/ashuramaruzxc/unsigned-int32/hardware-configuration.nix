{
  lib,
  config,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
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
      "hid_playstation" # for some reason dualsense acts as a mouse if it's not loaded early on
      "hid_apple"
    ];
    extraModulePackages = builtins.attrValues {
      inherit (config.boot.kernelPackages) zenpower v4l2loopback;
    };
    kernelParams = [
      ### ------------------------------------ ###
      # if thunderbolt turned off
      "ip=192.168.1.100::192.168.1.1:255.255.255.0::enp5s0:dhcp"
      "ip=192.168.1.110::192.168.1.1:255.255.255.0::enp7s0:dhcp"
      # if thunerbolt turned on
      "ip=192.168.1.100::192.168.1.1:255.255.255.0::enp57s0:dhcp"
      "ip=192.168.1.110::192.168.1.1:255.255.255.0::enp59s0:dhcp"
      ### ------------------------------------ ###
      "video=DP-1:2560x1440@120"
      "video=DP-2:2560x1440@120"
      "video=DP-3:2560x1440@120"
      "video=DP-4:2560x1440@120"
      "video=HDMI1:2560x1440@120"
      ### ------------------------------------ ###
      "nvidia_drm.fbdev=1"
      "iommu=pt"
      ### ------------------------------------ ###
      "nvme_core.default_ps_max_latency_us=0"
      "pcie_aspm=off"
      "pcie_port_pm=off"
    ];
    extraModprobeConfig = ''
      options hid_apple fnmode=2
    '';
    swraid = {
      enable = true;
      mdadmConf = ''
        HOMEHOST <ignore>
        ARRAY /dev/md/hddpool0 metadata=1.2 name=unsgined-int32:hddpool0 UUID=fe0631c5:f6957b40:6b696546:015251d0
        ARRAY /dev/md/nvmepool0 metadata=1.2 name=unsgined-int32:nvmepool0 UUID=22366d16:84656da4:2612b2de:a3e77bca
        MAILADDR ashuramaru@tenjin-dk.com
        MAILFROM no-reply@cloud.tenjin-dk.com
      '';
    };
    # Blacklisted Kernel modules do not change
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
      # font = "${pkgs.terminus_font_ttf}/share/fonts/truetype/TerminusTTF.ttf";
      # fontSize = 32;

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
  boot.plymouth = {
    enable = true;
    logo = "${pkgs.nixos-icons}/share/icons/hicolor/24x24/apps/nix-snowflake-white.png";
  };
  ### ----------------BOOT------------------- ###
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/D4E8-E96E";
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
          device = "/dev/disk/by-uuid/d4305e26-65e9-490d-aa42-299c6f0ca3ed";
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
  ### ---------------/dev/nvme0n1p2-------------------- ###
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/2faf4c47-1541-45de-ba3e-757a22818bf3";
    fsType = "btrfs";
    options = [
      "noatime"
      "autodefrag"
      "subvol=root"
      "space_cache=v2"
      "compress-force=zstd:1"
    ];
  };
  fileSystems."/var" = {
    device = "/dev/disk/by-uuid/2faf4c47-1541-45de-ba3e-757a22818bf3";
    fsType = "btrfs";
    options = [
      "noatime"
      "autodefrag"
      "subvol=var"
      "space_cache=v2"
      "compress-force=zstd:1"
    ];
    neededForBoot = true;
  };
  fileSystems."/var/log" = {
    device = "/dev/disk/by-uuid/2faf4c47-1541-45de-ba3e-757a22818bf3";
    fsType = "btrfs";
    options = [
      "noatime"
      "autodefrag"
      "subvol=log"
      "space_cache=v2"
      "compress-force=zstd:1"
    ];
    neededForBoot = true;
  };
  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/2faf4c47-1541-45de-ba3e-757a22818bf3";
    fsType = "btrfs";
    options = [
      "noatime"
      "subvol=nix"
      "autodefrag"
      "space_cache=v2"
      "compress-force=zstd:1"
    ];
  };
  fileSystems."/persist" = {
    device = "/dev/disk/by-uuid/2faf4c47-1541-45de-ba3e-757a22818bf3";
    fsType = "btrfs";
    options = [
      "noatime"
      "autodefrag"
      "subvol=persist"
      "space_cache=v2"
      "compress-force=zstd:1"
    ];
  };
  fileSystems."/Users" = {
    device = "/dev/disk/by-uuid/2faf4c47-1541-45de-ba3e-757a22818bf3";
    fsType = "btrfs";
    options = [
      "noatime"
      "autodefrag"
      "subvol=Users"
      "space_cache=v2"
      "compress-force=zstd:1"
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
  ### ---------------/dev/nvme0n1p2-------------------- ###

  ### ---------------/dev/md/nvmepool0-------------------- ###
  # fileSystems."/Shared/games" = {
  #   device = "/dev/nvmepool0/media";
  #   fsType = "btrfs";
  #   options = [
  #     "subvol=games"
  #     "noatime"
  #     "autodefrag"
  #   ];
  # };
  ### ---------------/dev/md/nvmepool0-------------------- ###

  ### ---------------/dev/md/hddpool0-------------------- ###
  fileSystems."/var/lib/backup/unsigned-int32" = {
    device = "/dev/hddpool0/backup";
    fsType = "btrfs";
    options = [
      "subvol=unsigned-int32"
      "noatime"
      "autodefrag"
      "compress-force=zstd:9"
    ];
  };
  fileSystems."/var/lib/backup/unsigned-int64" = {
    device = "/dev/hddpool0/backup";
    fsType = "btrfs";
    options = [
      "subvol=unsigned-int64"
      "noatime"
      "autodefrag"
      "compress-force=zstd:9"
    ];
  };
  fileSystems."/var/lib/backup/shared" = {
    device = "/dev/hddpool0/backup";
    fsType = "btrfs";
    options = [
      "subvol=shared"
      "noatime"
      "autodefrag"
      "compress-force=zstd:9"
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

  ### --------------- /dev/sda2(windows) --------------- ###
  fileSystems."/Shared/windows" = {
    device = "/dev/disk/by-uuid/E40A5B280A5AF750";
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
  ### --------------- /dev/sda2(windows) --------------- ###
  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
    fileSystems = [
      "/"
      "/var/lib/backup"
      # "/Shared/games"
    ];
  };
  services.fstrim = {
    enable = true;
    interval = "weekly";
  };
  system.fsPackages = [
    pkgs.sshfs
    pkgs.gphoto2fs
  ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
