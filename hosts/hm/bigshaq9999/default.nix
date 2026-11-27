{
  config,
  lib,
  pkgs,
  ...
}:
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
    pkgs.euro-office-desktopeditors
  ]
  ++ lib.lists.optional (!config.programs.antigravity-cli.enable) pkgs.antigravity-cli;
}
