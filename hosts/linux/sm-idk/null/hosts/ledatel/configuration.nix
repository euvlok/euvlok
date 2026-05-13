{ inputs, pkgs, ... }:
{
  imports = [
    ../common

    ./hardware-acceleration.nix
    ./hardware-configuration.nix

    inputs.home-manager.nixosModules.home-manager
    inputs.niri-flake-trivial.nixosModules.niri
    # inputs.nix-flatpak.nixosModules.nix-flatpak
    inputs.stylix-trivial.nixosModules.stylix
  ];

  nixos.steam.enable = true;

  home-manager = {
    useUserPackages = true;
    users.bruno = ../../home/home.nix;
    extraSpecialArgs = { inherit inputs; };
  };

  networking.hostName = "ledatel";

  environment.systemPackages = [
    pkgs.unstable.netdiscover
    pkgs.unstable.steam-run
  ];

  programs.nh.enable = true;

  # System services (tailscale is configured in mandatory modules)
  services.scx.enable = true;

  # The state version is required and should stay at the version you
  # originally installed.
  system.stateVersion = "25.05";
}
