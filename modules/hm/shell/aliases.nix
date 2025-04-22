{
  pkgs,
  lib,
  osConfig,
  ...
}:
let
  yt-dlp-script = lib.getExe (
    pkgs.writeScriptBin "yt-dlp-script" (builtins.readFile ../../../modules/scripts/yt-dlp-script.sh)
  );

  aliases = {
    # Navigate
    ".." = "../";
    ".3" = "../../";
    ".4" = "../../..";
    ".5" = "../../../../";
    cd = "z";
    dc = "z";

    # List
    ls = "eza --oneline --icons";
    lt = "eza --oneline --reverse --sort=size --icons";
    ll = "eza --long --icons";
    ld = "ls -d .*";

    # Time
    now = "date +'%T'";
    nowtime = "now";
    nowdate = "date +'%d-%m-%Y'";
    nowunix = "date +%s";

    # File Operations
    mv = "mv -iv";
    cp = "cp -iv";
    rm = "rm -v";
    mkdir = "mkdir -pv";
    untar = "tar -zxvf";

    # Video
    m4a = "${yt-dlp-script} m4a";
    m4a-cut = "${yt-dlp-script} m4a-cut";
    mp3 = "${yt-dlp-script} mp3";
    mp3-cut = "${yt-dlp-script} mp3-cut";
    mp4 = "${yt-dlp-script} mp4";
    mp4-cut = "${yt-dlp-script} mp4-cut";

    # Misc
    myip = "curl 'https://ipinfo.io/ip'";

    # Nix Aliases
    nix-build-file = ''
      f() {
        file="$1"
        args="''${2:-{}}"
        nix-build -E "with import (builtins.getFlake 'nixpkgs') {}; callPackage ./$file $args"
      }; f
    '';

    rebuild =
      if osConfig.nixpkgs.hostPlatform.isLinux then
        "nixos-rebuild switch --use-remote-sudo --flake /etc/nixos/"
      else
        "darwin-rebuild switch --flake /etc/nixos/";

    update = ''
      __nixos_flake_update_func() {
        nix_user="$(whoami)"
        nix_host="$(hostname | sed 's/\.local$//')"
        flake_path="/etc/nixos"
        flake_eval_path="/etc/nixos"
        if [[ "$(uname -s)" == "Darwin" ]]; then
          flake_attr="darwinConfigurations"
        else
          flake_attr="nixosConfigurations"
        fi
        github_username=$(nix eval --raw --impure \
          --expr "
            let
              flake = builtins.getFlake \"$flake_eval_path\";
              host = flake.''${flake_attr}.\"''${nix_host}\";
              user = \"''${nix_user}\";
            in
              host.config.home-manager.users.\''${user}.programs.git.userName
          " | tr '[:upper:]' '[:lower:]')
        matching_inputs=$(nix eval --json --impure \
          --expr '(builtins.attrNames (builtins.getFlake "'"$flake_eval_path"'").inputs)' \
          | jq -r --arg pattern "-''${github_username}" '.[] | select(endswith($pattern))')
        nix flake update $matching_inputs --flake "$flake_path"
      }; __nixos_flake_update_func
    '';
  };
in
{
  programs.bash.shellAliases = aliases;
  programs.zsh.shellAliases = aliases;
}
