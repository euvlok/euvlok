{ inputs, ... }:
{
  imports = [
    inputs.catppuccin-trivial.nixosModules.catppuccin
    ../cross
    ../lib
    ./amd.nix
    ./audio.nix
    ./boot.nix
    ./gnome.nix
    ./hardware.nix
    ./kanata.nix
    ./locale.nix
    ./networking.nix
    ./nix.nix
    ./nvidia.nix
    ./plasma.nix
    ./security.nix
    ./services.nix
    ./sessionVariables.nix
    ./sops.nix
    ./steam.nix
    ./vscode-server.nix
    ./zram.nix
  ];
}
