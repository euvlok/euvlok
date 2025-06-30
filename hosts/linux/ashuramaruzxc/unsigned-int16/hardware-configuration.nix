{ pkgs, lib, ... }:
let
  firmwarePartition = lib.recursiveUpdate {
    # label = "FIRMWARE";
    priority = 1;

    type = "0700"; # Microsoft basic data
    attributes = [
      0 # Required Partition
    ];

    size = "1024M";
    content = {
      type = "filesystem";
      format = "vfat";
      # mountpoint = "/boot/firmware";
      mountOptions = [
        "noatime"
        "noauto"
        "x-systemd.automount"
        "x-systemd.idle-timeout=1min"
      ];
    };
  };

  espPartition = lib.recursiveUpdate {
    # label = "ESP";

    type = "EF00"; # EFI System Partition (ESP)
    attributes = [
      2 # Legacy BIOS Bootable, for U-Boot to find extlinux config
    ];

    size = "1024M";
    content = {
      type = "filesystem";
      format = "vfat";
      # mountpoint = "/boot";
      mountOptions = [
        "noatime"
        "noauto"
        "x-systemd.automount"
        "x-systemd.idle-timeout=1min"
        "umask=0077"
      ];
    };
  };
in
{
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  boot.supportedFilesystems = [ "zfs" ];
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;

  disko.devices = {
    disk.nvme0 = {
      type = "disk";
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {

          FIRMWARE = firmwarePartition {
            label = "FIRMWARE";
            content.mountpoint = "/boot/firmware";
          };

          ESP = espPartition {
            label = "ESP";
            content.mountpoint = "/boot";
          };

          zfs = {
            size = "100%";
            content = {
              type = "zfs";
              pool = "rpool"; # zroot
            };
          };

        };
      };
    }; # nvme0

    zpool = {
      rpool = {
        type = "zpool";

        # zpool properties
        options = {
          ashift = "12";
          autotrim = "on"; # see also services.zfs.trim.enable
        };

        # zfs properties
        rootFsOptions = {
          # "com.sun:auto-snapshot" = "false";
          # https://jrs-s.net/2018/08/17/zfs-tuning-cheat-sheet/
          compression = "lz4";
          atime = "off";
          xattr = "sa";
          acltype = "posixacl";
          # https://rubenerd.com/forgetting-to-set-utf-normalisation-on-a-zfs-pool/
          normalization = "formD";
          dnodesize = "auto";
          mountpoint = "none";
          canmount = "off";
        };

        postCreateHook =
          let
            poolName = "rpool";
          in
          "zfs list -t snapshot -H -o name | grep -E '^${poolName}@blank$' || zfs snapshot ${poolName}@blank";

        datasets = {

          # stuff which can be recomputed/easily redownloaded, e.g. nix store
          local = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };
          "local/nix" = {
            type = "zfs_fs";
            options = {
              reservation = "128M";
              mountpoint = "legacy"; # to manage "with traditional tools"
            };
            mountpoint = "/nix"; # nixos configuration mountpoint
          };

          # _system_ data
          system = {
            type = "zfs_fs";
            options = {
              mountpoint = "none";
            };
          };
          "system/root" = {
            type = "zfs_fs";
            options = {
              mountpoint = "legacy";
            };
            mountpoint = "/";
          };
          "system/var" = {
            type = "zfs_fs";
            options = {
              mountpoint = "legacy";
            };
            mountpoint = "/var";
          };

          # _user_ and _user service_ data. safest, long retention policy
          safe = {
            type = "zfs_fs";
            options = {
              copies = "2";
              mountpoint = "none";
            };
          };
          "safe/home" = {
            type = "zfs_fs";
            options = {
              mountpoint = "legacy";
            };
            mountpoint = "/home";
          };
          "safe/var/lib" = {
            type = "zfs_fs";
            options = {
              mountpoint = "legacy";
            };
            mountpoint = "/var/lib";
          };

        };
      };
    };
  };

  boot = {
    tmp.useTmpfs = true;
    loader.raspberryPi = {
      bootloader = "uboot";
      firmwarePackage = pkgs.linuxAndFirmware.v6_12_25.raspberrypifw;
    };
    kernelPackages = pkgs.linuxAndFirmware.v6_12_25.linuxPackages_rpi5;
  };

  console.earlySetup = true;
  console.font = lib.mkDefault "${pkgs.terminus_font}/share/consolefonts/ter-u16n.psf.gz";

  system.fsPackages = [ pkgs.sshfs ];
  environment.systemPackages = [ pkgs.cifs-utils ];

  hardware.raspberry-pi.config = {
    all = {
      # [all] conditional filter, https://www.raspberrypi.com/documentation/computers/config_txt.html#conditional-filters
      options = {
        # https://www.raspberrypi.com/documentation/computers/config_txt.html#enable_uart
        # in conjunction with `console=serial0,115200` in kernel command line (`cmdline.txt`)
        # creates a serial console, accessible using GPIOs 14 and 15 (pins
        #  8 and 10 on the 40-pin header)
        enable_uart = {
          enable = true;
          value = true;
        };
        # https://www.raspberrypi.com/documentation/computers/config_txt.html#uart_2ndstage
        # enable debug logging to the UART, also automatically enables
        # UART logging in `start.elf`
        uart_2ndstage = {
          enable = true;
          value = true;
        };
      };
      # Base DTB parameters
      # https://github.com/raspberrypi/linux/blob/a1d3defcca200077e1e382fe049ca613d16efd2b/arch/arm/boot/dts/overlays/README#L132
      base-dt-params = {

        # https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#enable-pcie
        pciex1 = {
          enable = true;
          value = "on";
        };
        # PCIe Gen 3.0
        # https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#pcie-gen-3-0
        pciex1_gen = {
          enable = true;
          value = "3";
        };
      };
    };
  };
}
