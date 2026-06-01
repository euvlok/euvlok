{ inputs, ... }:
{
  imports = [
    inputs.catppuccin-trivial.nixosModules.catppuccin
    ../cross
    ./amd.nix
    ./audio.nix
    ./boot.nix
    ./cosmic.nix
    ./ghidra-mcp.nix
    ./gnome.nix
    ./hardware.nix
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
    ./zed-remote.nix
    ./zram.nix
  ];
}
