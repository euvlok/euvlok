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
    ../shared/programs.nix
    ./services.nix
  ];

  euvlok.nixos.boot.systemd-boot.enable = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.loader.systemd-boot.memtest86.enable = true;

  networking = {
    hostName = "nyx";
    firewall.enable = true;
  };

  euvlok = {
    nix.buildParallelism = {
      maxJobs = 1;
      cores = 1;
    };
    nixos.locale = {
      enable = true;
      timeZone = "America/Chicago";
    };
  };

  nix.settings = {
    eval-cores = 1;
    trusted-users = [
      "hushh"
      "@wheel"
    ];
  };

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

  environment.variables = {
    TERMINAL = "alacritty";
    EDITOR = "nvim";
    TERM = "alacritty";
  };

  hardware.graphics = {
    enable32Bit = lib.modules.mkForce false;
    extraPackages32 = lib.modules.mkForce [ ];
  };

  powerManagement.enable = true;
  virtualisation.libvirtd.enable = true;

  system.fsPackages = [ pkgs.sshfs ];
  system.stateVersion = "26.05";
}
