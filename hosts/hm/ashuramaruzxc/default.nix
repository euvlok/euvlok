_: {
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
}
