{ config, lib, ... }: {
  imports = [
    ./aliases.nix
    ./chromium
    (import ../../../slop.nix).homeManager.personal
    ./dconf.nix
    ./firefox
    ./git.nix
    ./helix.nix
    ../shared/nixcord.nix
    ./ssh.nix
    ./starship.nix
    ../shared/vscode.nix
    ./zed.nix
  ];

  programs.ghostty.settings.font-family = lib.modules.mkIf config.euvlok.home.codex.enable "Hack Nerd Font Mono";
}
