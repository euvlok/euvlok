{
  inputs,
  lib,
  ...
}:
let
  peripheralFirmware =
    lib.findFirst (path: builtins.pathExists (path + "/all_firmware.tar.gz")) null
      [
        /boot/asahi
        /mnt/boot/asahi
      ];
in
{
  imports = [
    ../common

    ./hardware-configuration.nix
    ./hardware-asahi.nix

    inputs.home-manager.nixosModules.home-manager
    inputs.niri-flake-trivial.nixosModules.niri
    inputs.stylix-trivial.nixosModules.stylix
    inputs.nixos-apple-silicon.nixosModules.apple-silicon-support
    inputs.steam-asahi.nixosModules.default
  ];

  programs.steam-asahi.enable = true;

  programs.kdeconnect.enable = true;

  home-manager = {
    useUserPackages = true;
    users.bruno = ../../home/home.nix;
    extraSpecialArgs = { inherit inputs; };
  };

  networking.hostName = "zero";

  # Apple Silicon specific configuration
  boot.loader.efi.canTouchEfiVariables = false;
  boot.kernelParams = [ "appledrm.show_notch=1" ];

  # Asahi/Apple Silicon systems commonly use 16K pages, where the NixOS
  # default of 33 ASLR bits is invalid. 31 is the maximum for this layout.
  boot.kernel.sysctl."vm.mmap_rnd_bits" = lib.mkForce 31;
  security.rtkit.enable = lib.mkForce true;

  # The Asahi installer extracts this non-redistributable firmware from macOS
  # onto the EFI system partition. Use it when present, but keep CI and
  # cross-builds working on machines that do not have this host's ESP mounted.
  hardware.asahi.peripheralFirmwareDirectory = peripheralFirmware;
  hardware.asahi.extractPeripheralFirmware = peripheralFirmware != null;

  # Build the heavy asahi packages (kernel, u-boot, m1n1, asahi-fwextract)
  # against nixpkgs-unstable so we hit the nixos-apple-silicon Cachix cache.
  # The CI at github.com/nix-community/nixos-apple-silicon only publishes
  # builds against unstable variants on `main`, so 25.11-built kernels miss.
  hardware.asahi.pkgs = lib.mkForce (
    import inputs.nixpkgs-unstable-small {
      localSystem.system = "aarch64-linux";
      config.allowUnfree = true;
      overlays = [ inputs.nixos-apple-silicon.overlays.apple-silicon-overlay ];
    }
  );

  nixpkgs.config.allowUnsupportedSystem = true;

  programs = {
    wireshark = {
      enable = true;
      dumpcap.enable = true;
    };
  };

  services.power-profiles-daemon.enable = false;

  services.tlp.enable = true;
  services.tlp.settings = {
    START_CHARGE_THRESH_BAT0 = 70;
    STOP_CHARGE_THRESH_BAT0 = 80;
  };

  # System services
  services.fstrim.enable = true;

  # The state version is required and should stay at the version you
  # originally installed.
  system.stateVersion = "25.11";
}
