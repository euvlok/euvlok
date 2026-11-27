{ pkgs, ... }:
{
  imports = [
    ./git.nix
    ./ghostty.nix
    ./mitos.nix
    ./mpv.nix
    ./nixcord.nix
    ./ssh.nix
    ./starship.nix
    ../shared/nixcord.nix
  ];

  home.packages = [
    pkgs.antigravity-cli
    pkgs.euro-office-desktopeditors
  ];
}
