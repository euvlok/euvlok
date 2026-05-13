{ inputs, pkgs, ... }:
{
  imports = [
    ./networking.nix
    inputs.self.nixosModules.default
  ];

  nixos = {
    gnome.enable = true;
    locale = {
      enable = true;
      timeZone = "Europe/Warsaw";
      defaultLocale = "en_US.UTF-8";
      extraLocaleSettings = {
        LC_ADDRESS = "pl_PL.UTF-8";
        LC_IDENTIFICATION = "pl_PL.UTF-8";
        LC_MEASUREMENT = "pl_PL.UTF-8";
        LC_MONETARY = "pl_PL.UTF-8";
        LC_NAME = "pl_PL.UTF-8";
        LC_NUMERIC = "pl_PL.UTF-8";
        LC_PAPER = "pl_PL.UTF-8";
        LC_TELEPHONE = "pl_PL.UTF-8";
        LC_TIME = "pl_PL.UTF-8";
      };
    };
    zram.enable = true;
  };

  console.keyMap = "pl2";
  zramSwap.algorithm = "zstd";

  nix.settings.extra-substituters = [
    "https://nixos-apple-silicon.cachix.org"
    "https://vicinae.cachix.org"
  ];
  nix.settings.extra-trusted-public-keys = [
    "nixos-apple-silicon.cachix.org-1:8psDu5SA5dAD7qA0zMy5UT292TxeEPzIz8VVEr2Js20="
    "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
  ];

  boot = {
    supportedFilesystems = [ "ntfs" ];
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    # kernelPackages = pkgs.linuxPackages_latest;
    # kernelPackages = pkgs.linuxPackages_cachyos-lts;
    # kernelPackages = pkgs.linuxPackages_cachyos-gcc;
    consoleLogLevel = 0;
    initrd.verbose = false;
  };

  # services.displayManager.ly.enable = true;
  services.displayManager.gdm.enable = true;
  # services.desktopManager.gnome.enable = true;
  # services.desktopManager.cosmic.enable = true;
  # services.desktopManager.cosmic.xwayland.enable = true;

  home-manager.backupFileExtension = "bak";

  # Hardware
  hardware.bluetooth.enable = true;
  powerManagement.enable = true;

  # User
  users.mutableUsers = true;
  users.users.bruno = {
    isNormalUser = true;
    hashedPassword = "$y$j9T$mvJlLXGvrwdfLcPVpgL2V.$tGJiUax1vrFDtDhtljQ.q749KII4oUnx0dJph3zJCj1";
    description = "Bruno";
    extraGroups = [
      "networkmanager"
      "video"
      "wheel"
      "seat"
    ];
  };

  programs.niri.enable = true;

  # Enable Wireshark with USB support
  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark; # otherwise you get the CLI version
    usbmon.enable = true; # enable USB capture
    dumpcap.enable = true; # enable network capture
  };
  # Add your user account to the Wireshark group
  users.groups.wireshark.members = [ "bruno" ];

  services.printing.enable = true;

  # Enable nix-ld for LSP servers downloaded by Zed
  programs.nix-ld.enable = true;

  programs.virt-manager.enable = true;
  users.groups.libvirtd.members = [ "bruno" ];
  virtualisation.libvirtd.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;
}
