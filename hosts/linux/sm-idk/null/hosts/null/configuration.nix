{ inputs, ... }:
{
  imports = [
    ../common

    ./nvidia.nix
    ./hardware-configuration.nix

    inputs.home-manager.nixosModules.home-manager
    inputs.niri-flake-trivial.nixosModules.niri
    # inputs.nix-flatpak.nixosModules.nix-flatpak
    inputs.stylix-trivial.nixosModules.stylix
  ];

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  nixos.steam.enable = true;

  home-manager = {
    useUserPackages = true;
    users.bruno = ../../home/home.nix;
    extraSpecialArgs = { inherit inputs; };
  };

  networking.hostName = "null";

  # Hardware
  hardware.uinput.enable = true;

  services.scx.enable = true;

  # The state version is required and should stay at the version you
  # originally installed.
  system.stateVersion = "25.05";
}
