{
  imports = [
    ./aliases.nix
    ./bash.nix
    ./fish.nix
    ./zsh.nix
  ];

  home.sessionPath = map (directory: "$HOME/${directory}/bin") [
    ".bun"
    ".npm"
    ".local"
    ".cargo"
    ".go"
    "go"
    ".yarn"
    ".deno"
    ".ghcup"
    ".local/share/pnpm"
  ];
}
