{ pkgs, ... }:
let
  aliases = {
    # Navigate
    ".." = "../";
    ".3" = "../../";
    ".4" = "../../..";
    ".5" = "../../../../";
    cd = "z";
    dc = "z";

    # List
    ls = "eza --oneline --icons auto";
    lt = "eza --oneline --reverse --sort=size --icons";
    ll = "eza --long --icons auto";
    ld = "ls -d .*";

    # File Operations
    mv = "mv -iv";
    cp = "cp -iv";
    rm = "rm -v";
    mkdir = "mkdir -pv";
    untar = "tar -zxvf";

    # Video
    # yt-dlp-script is our own custom package
    m4a = "yt-dlp-script m4a";
    m4a-cut = "yt-dlp-script m4a-cut";
    mp3 = "yt-dlp-script mp3";
    mp3-cut = "yt-dlp-script mp3-cut";
    mp4 = "yt-dlp-script mp4";
    mp4-cut = "yt-dlp-script mp4-cut";

    # Modern Replacements
    vi = "hx";
    vim = "hx";
    htop = "btop";
    neofetch = "fastfetch";

    now = "date +'%T'";
    nowtime = "now";
    nowdate = "date +'%d-%m-%Y'";
    nowunix = "date +%s";

    # Utility
    bc = "bc -l";

    # Misc
    myip = "curl 'https://ipinfo.io/ip'";
  };

  bourneAliases = {
    # Nix Aliases
    nix-build-file = ''
      __02fda1f0() {
        file="$1"
        args="''${2:-{}}"
        nix-build -E "with import <nixpkgs> {}; callPackage ./$file $args"
      }; __02fda1f0
    '';

    clean-roots = ''
      nix-store --gc --print-roots \
      | rg --no-filename -v '^(/nix/var|/run/\w+-system|\{|/proc)' \
      | rg --no-filename -v 'home-manager|flake-registry\.json' \
      | rg --no-filename -o -r '$1' '^(\S+)' \
      | xargs -L1 unlink
    '';

    rebuild =
      if pkgs.stdenvNoCC.hostPlatform.isLinux then
        "nixos-rebuild switch --use-remote-sudo --flake $(readlink -f /etc/nixos)"
      else
        "sudo nix-darwin switch --flake $(readlink -f /etc/nixos)";

    # Shared and contributor inputs have independent lockfiles
    update = ''nix flake update --flake "$(readlink -f /etc/nixos)"'';
    update-users = ''nix flake update --flake "$(readlink -f /etc/nixos)/flake-modules/users"'';
  };
in
{
  home.shellAliases = aliases;
  programs.bash.shellAliases = bourneAliases;
  programs.zsh.shellAliases = bourneAliases;
}
