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
  ];

  # Temporary workaround: XanMod 7.3.3 already includes this patch.
  boot.kernelPackages = pkgs.linuxPackagesFor (
    pkgs.linux_xanmod_latest.override (old: {
      kernelPatches = builtins.filter (
        patch: (patch.name or "") != "tools-add-128-bit-integer-types-for-aarch64"
      ) (old.kernelPatches or [ ]);
    })
  );
  boot.kernel.sysctl = {
    "kernel.split_lock_mitigate" = 0;
    "vm.swappiness" = 60;
    "vm.vfs_cache_pressure" = 75;
  };

  # 4 GiB logical capacity; compressed pages allocate RAM on demand.
  # Prefer zram to disk swap without enabling the shared module's sysctl tuning.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryMax = 4 * 1024 * 1024 * 1024;
    priority = 15;
  };

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 8 * 1024;
      randomEncryption.enable = true;
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

  nix.settings = {
    # max-jobs = 12;
    trusted-users = [
      "hushh"
      "@wheel"
    ];
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
      "libvirtd"
      "wireshark"
    ];
    shell = pkgs.fish;
  };

  networking.firewall.enable = false;

  # Set some annoying env vars to make sure gayland and nshitia play nice together
  environment.variables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    NVD_BACKEND = "direct";
    WLR_DRM_NO_ATOMIC = "1";
    TERMINAL = "alacritty";
    EDITOR = "nvim";
    TERM = "alacritty";
  };

  virtualisation.libvirtd.enable = true;

  system.fsPackages = with pkgs; [
    sshfs
  ];

  system.stateVersion = "26.11";
}
