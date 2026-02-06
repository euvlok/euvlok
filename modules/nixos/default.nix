{ inputs, ... }:
{
  imports = [
    inputs.catppuccin-trivial.nixosModules.catppuccin
    ../cross
    ../lib
    ./amd.nix
    ./audio.nix
    ./gnome.nix
    ./hardware.nix
    ./kanata.nix
    ./networking.nix
    ./nix.nix
    ./nvidia.nix
    ./plasma.nix
    ./security.nix
    ./services.nix
    ./sessionVariables.nix
    ./steam.nix
    ./vscode-server.nix
    ./zram.nix
  ];
}
