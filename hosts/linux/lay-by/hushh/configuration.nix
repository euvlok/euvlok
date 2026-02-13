{ pkgs, ... }:
{
  imports = [
    ./fonts.nix
    ./hardware-configuration.nix
    ./packages.nix
    ./programs.nix
    ./services.nix
    ./slsk.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.memtest86.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "blind-faith";

  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  security.polkit = {
    enable = true;
    adminIdentities = [ "unix-group:wheel" ];
  };

  nix.settings.max-jobs = 6;

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

  system.stateVersion = "25.05";
}
