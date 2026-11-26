{ zenBrowserPackage }:
{
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../shared/fonts.nix
    ./hardware-configuration.nix
    (lib.modules.importApply ./packages.nix { inherit zenBrowserPackage; })
    ./programs.nix
    ./services.nix
  ];

  euvlok.nixos.boot.systemd-boot.enable = true;
  boot.loader.systemd-boot.memtest86.enable = true;
  # Initialize the display before the initrd asks for the LUKS passphrase.
  boot.initrd.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_drm"
  ];
  boot.kernelModules = [ "ntsync" ];
  # Keep the boot console at DP-1's native width instead of HDMI's narrower width.
  boot.kernelParams = [
    "video=HDMI-A-1:d"
    "preempt=full"
    "nowatchdog"
  ];

  boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;
  boot.kernel.sysctl = {
    "kernel.split_lock_mitigate" = 0;
    "kernel.nmi_watchdog" = 0;
    "vm.swappiness" = 100;
    "vm.vfs_cache_pressure" = 50;
    "vm.page-cluster" = 0;
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
    "vm.dirty_bytes" = 268435456;
    "vm.dirty_background_bytes" = 67108864;
    "vm.dirty_writeback_centisecs" = 1500;
    "vm.compaction_proactiveness" = 0;
    "net.core.netdev_max_backlog" = 4096;
    "net.ipv4.tcp_fastopen" = 3;
  };

  systemd.tmpfiles.settings."10-thp-gaming" = {
    "/sys/kernel/mm/transparent_hugepage/enabled".w.argument = "madvise";
    "/sys/kernel/mm/transparent_hugepage/defrag".w.argument = "defer+madvise";
    "/sys/kernel/mm/transparent_hugepage/shmem_enabled".w.argument = "advise";
    "/sys/kernel/mm/transparent_hugepage/khugepaged/max_ptes_none".w.argument = "409";
  };

  boot.initrd.luks.devices."luks-78ea3416-4e3a-4009-93a2-375fb7872b9e" = {
    allowDiscards = true;
    bypassWorkqueues = true;
  };

  fileSystems."/".options = [
    "defaults"
    "noatime"
  ];

  fileSystems."/media/HDD".options = [
    "defaults"
    "noatime"
    "compress=zstd:1"
  ];

  # Allocate up to 75% of RAM as logical zram capacity on demand before hitting
  # the disk swapfile, without enabling the shared zram module's swappiness=180.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 75;
    priority = 100;
  };

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 8 * 1024;
      randomEncryption.enable = false;
    }
  ];

  networking.hostName = "blind-faith";

  euvlok.nixos.locale = {
    enable = true;
    timeZone = "America/Chicago";
  };

  security.polkit = {
    enable = true;
    adminIdentities = [ "unix-group:wheel" ];
  };

  security.pam.loginLimits = [
    {
      domain = "@gamemode";
      type = "soft";
      item = "nice";
      value = "-20";
    }
    {
      domain = "@gamemode";
      type = "hard";
      item = "nice";
      value = "-20";
    }
  ];

  nix = {
    daemonCPUSchedPolicy = "batch";
    daemonIOSchedClass = "idle";
    settings = {
      # max-jobs = 12;
      trusted-users = [
        "hushh"
        "@wheel"
      ];
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.hushh = {
    isNormalUser = true;
    description = "hushh";
    extraGroups = [
      "networkmanager"
      "wheel"
      "input"
      "disk"
      "gamemode"
      "libvirtd"
      "wireshark"
    ];
    shell = pkgs.fish;
  };

  networking.firewall.enable = false;

  euvlok.nixos.gui.wlrootsWorkarounds = false;

  hardware.nvidia.moduleParams.nvidia.NVreg_EnablePCIERelaxedOrderingMode = 1;

  environment = {
    sessionVariables = {
      __GL_SHADER_DISK_CACHE = "1";
      __GL_SHADER_DISK_CACHE_SIZE = "10737418240";
      __GL_SHADER_DISK_CACHE_SKIP_CLEANUP = "1";
    };
    variables = {
      TERMINAL = "alacritty";
      EDITOR = "nvim";
      TERM = "alacritty";
    };
  };

  virtualisation.libvirtd.enable = true;

  system.fsPackages = [ pkgs.sshfs ];

  system.stateVersion = "26.11";
}
