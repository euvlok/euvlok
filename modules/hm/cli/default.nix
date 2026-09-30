{
  imports = [
    (import ../../../slop.nix).homeManager.cli
    ./devenv.nix
    ./direnv.nix
    ./fastfetch
    ./fzf.nix
    ./git.nix
    ./jujutsu.nix
    ./nh.nix
    ./ssh.nix
    ./zoxide.nix
  ];
}
