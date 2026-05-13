{ inputs, ... }:
{
  imports = [
    ../common

    ./hardware-acceleration.nix
    ./hardware-configuration.nix

    inputs.home-manager.nixosModules.home-manager
    inputs.niri.nixosModules.niri
    # inputs.nix-flatpak.nixosModules.nix-flatpak
    inputs.stylix.nixosModules.stylix
  ];

  # nixos.steam.enable = true;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.bruno = ../../home/home.nix;
    extraSpecialArgs = { inherit inputs; };
  };

  networking.hostName = "laptop";

  # System services (tailscale is configured in mandatory modules)
  services.scx.enable = true;

  # The state version is required and should stay at the version you
  # originally installed.
  system.stateVersion = "25.05";
}
