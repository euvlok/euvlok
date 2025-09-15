{ pkgs, lib, ... }:
{
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  boot = {
    kernelPackages = pkgs.linuxAndFirmware.v6_12_44.linuxPackages_rpi5;
    loader.raspberryPi = {
      bootloader = "kernel";
    };
    tmp.useTmpfs = true;
    supportedFilesystems = [ "zfs" ];

    kernelParams = [ "zfs.zfs_arc_max=1610612736" ];
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
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot/firmware";
              mountOptions = [
                "noatime"
                "noauto"
                "x-systemd.automount"
                "x-systemd.idle-timeout=1min"
              ];
            };
          };
          ESP = {
            label = "ESP";
            type = "EF00";
            attributes = [ 2 ]; # Legacy BIOS Bootable
            size = "1024M";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [
                "noatime"
                "noauto"
                "x-systemd.automount"
                "x-systemd.idle-timeout=1min"
                "umask=0077"
              ];
            };
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
        local = {
          type = "zfs_fs";
          options.mountpoint = "none";
        };
        "local/nix" = {
          type = "zfs_fs";
          options = {
            reservation = "128M";
            mountpoint = "legacy";
          };
          mountpoint = "/nix";
        };

        system = {
          type = "zfs_fs";
          options.mountpoint = "none";
        };
        "system/root" = {
          type = "zfs_fs";
          options.mountpoint = "legacy";
          mountpoint = "/";
        };
        "system/var" = {
          type = "zfs_fs";
          options.mountpoint = "legacy";
          mountpoint = "/var";
        };

        safe = {
          type = "zfs_fs";
          options = {
            copies = "2";
            mountpoint = "none";
          };
        };
        "safe/home" = {
          type = "zfs_fs";
          options.mountpoint = "legacy";
          mountpoint = "/home";
        };
        "safe/var/lib" = {
          type = "zfs_fs";
          options.mountpoint = "legacy";
          mountpoint = "/var/lib";
        };
      };
    };
  };

  hardware.raspberry-pi.config.all = {
    # [all] conditional filter
    options = {
      # Serial console on GPIO 14/15
      enable_uart = {
        enable = true;
        value = true;
      };
      # Debug logging to UART
      uart_2ndstage = {
        enable = true;
        value = true;
      };
    };
    base-dt-params = {
      # Enable PCIe
      pciex1 = {
        enable = true;
        value = "on";
      };
      # PCIe Gen 3.0
      pciex1_gen = {
        enable = true;
        value = "3";
      };
    };
  };

  services.zfs = {
    autoScrub.enable = true;
    trim.enable = true;
  };
  system.fsPackages = [ pkgs.sshfs ];
  environment.systemPackages = [ pkgs.cifs-utils ];
  #!README
  /**
    * https://www.raspberrypi.com/documentation/computers/config_txt.html#conditional-filters
    * https://www.raspberrypi.com/documentation/computers/config_txt.html#enable_uart
    * https://www.raspberrypi.com/documentation/computers/config_txt.html#uart_2ndstage
    * https://github.com/raspberrypi/linux/blob/a1d3defcca200077e1e382fe049ca613d16efd2b/arch/arm/boot/dts/overlays/README#L132
    * https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#enable-pcie
    * https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#pcie-gen-3-0
  */
}
