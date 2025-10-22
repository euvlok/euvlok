{ osConfig, lib, ... }:
{
  imports = [
    ./aliases.nix
    ./git.nix
    ./helix.nix
    ./nushell.nix
    ./ssh.nix
    ./starship.nix
  ]
  ++
    lib.optionals
      (osConfig.nixos.nvidia.enable or osConfig.nixos.amd.enable or osConfig.nixpkgs.hostPlatform.isDarwin
      )
      [
        ./firefox.nix
        ./nixcord.nix
        ./vscode.nix
      ]
  ++
    lib.optionals
      (
        (osConfig.nixos.nvidia.enable or osConfig.nixos.amd.enable) && osConfig.nixpkgs.hostPlatform.isLinux
      )
      [
        ./chrome.nix
        ./dconf.nix
        ./flatpak.nix
        ./graphics.nix
      ];
}
