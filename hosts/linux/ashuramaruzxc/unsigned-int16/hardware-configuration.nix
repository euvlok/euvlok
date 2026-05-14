{ pkgs, lib, ... }:
let
  bootMountOptions = [
    "noatime"
    "noauto"
    "x-systemd.automount"
    "x-systemd.idle-timeout=1min"
  ];

  bootEspMountOptions = bootMountOptions ++ [ "umask=0077" ];

  vfatFilesystem = {
    type = "filesystem";
    format = "vfat";
  };

  zfsContainer = {
    type = "zfs_fs";
    options.mountpoint = "none";
  };

  zfsLegacyDataset = {
    type = "zfs_fs";
    options.mountpoint = "legacy";
  };

  zfsMount = dataset: {
    device = "rpool/${dataset}";
    fsType = "zfs";
    options = [ "defaults" ];
  };

  enabledConfig = value: {
    enable = true;
    inherit value;
  };
in
{
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  boot = {
    loader.raspberry-pi.bootloader = "kernel";
    kernelPackages = pkgs.linuxAndFirmware.v6_12_85.linuxPackages_rpi5;
    kernelParams = [ "zfs.zfs_arc_max=1610612736" ];
    supportedFilesystems = [ "zfs" ];
    zfs.forceImportRoot = false;
    tmp.useTmpfs = true;
  };

  disko.devices = {
    disk.nvme0 = {
      type = "disk";
      device = "/dev/nvme0n1";

      content = {
        type = "gpt";

        partitions = {
          FIRMWARE = {
            label = "FIRMWARE";
            priority = 1;
            type = "0700";
            attributes = [ 0 ];
            size = "1024M";
            content = vfatFilesystem;
          };

          ESP = {
            label = "ESP";
            type = "EF00";
            attributes = [ 2 ]; # Legacy BIOS Bootable
            size = "1024M";
            content = vfatFilesystem;
          };

          zfs = {
            size = "100%";
            content = {
              type = "zfs";
              pool = "rpool";
            };
          };
        };
      };
    };

    zpool.rpool = {
      type = "zpool";

      options = {
        ashift = "12";
        autotrim = "on";
      };

      rootFsOptions = {
        compression = "lz4";
        atime = "off";
        xattr = "sa";
        acltype = "posixacl";
        normalization = "formD";
        dnodesize = "auto";
        mountpoint = "none";
        canmount = "off";
      };
      postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^rpool@blank$' || zfs snapshot rpool@blank";

      datasets = {
        local = zfsContainer;

        "local/nix" = {
          type = "zfs_fs";
          options = {
            mountpoint = "legacy";
            reservation = "128M";
          };
        };

        system = zfsContainer;
        "system/root" = zfsLegacyDataset;
        "system/var" = zfsLegacyDataset;

        safe = {
          type = "zfs_fs";
          options = {
            copies = "2";
            mountpoint = "none";
          };
        };
        "safe/home" = zfsLegacyDataset;
        "safe/var/lib" = zfsLegacyDataset;
      };
    };
  };

  # Disko creates the ZFS datasets; NixOS owns the active mounts.
  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-partlabel/ESP";
      fsType = "vfat";
      options = bootEspMountOptions;
    };

    "/boot/firmware" = {
      device = "/dev/disk/by-partlabel/FIRMWARE";
      fsType = "vfat";
      options = bootMountOptions;
    };

    "/" = zfsMount "system/root";
    "/nix" = zfsMount "local/nix";
    "/var" = zfsMount "system/var";
    "/var/lib" = zfsMount "safe/var/lib";
    "/home" = zfsMount "safe/home";
  };

  # Raspberry Pi config.txt references:
  # - https://www.raspberrypi.com/documentation/computers/config_txt.html#conditional-filters
  # - https://www.raspberrypi.com/documentation/computers/config_txt.html#enable_uart
  # - https://www.raspberrypi.com/documentation/computers/config_txt.html#uart_2ndstage
  # - https://github.com/raspberrypi/linux/blob/a1d3defcca200077e1e382fe049ca613d16efd2b/arch/arm/boot/dts/overlays/README#L132
  # - https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#enable-pcie
  # - https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#pcie-gen-3-0
  hardware.raspberry-pi.config.all = {
    options = {
      # Serial console on GPIO 14/15
      enable_uart = enabledConfig true;
      # Debug logging to UART
      uart_2ndstage = enabledConfig true;
    };

    base-dt-params = {
      # Enable PCIe
      pciex1 = enabledConfig "on";
      # PCIe Gen 3.0
      pciex1_gen = enabledConfig "3";
    };
  };

  services.zfs = {
    autoScrub.enable = true;
    trim.enable = true;
  };

  system.fsPackages = [ pkgs.sshfs ];
  environment.systemPackages = [ pkgs.cifs-utils ];
}
