{
  pkgs,
  lib,
  osConfig,
  ...
}:
let
  yt-dlp-script = lib.getExe (
    pkgs.writeShellApplication {
      name = "yt-dlp-script";
      text = builtins.readFile ../../../modules/scripts/yt-dlp-script.sh;
      runtimeInputs = builtins.attrValues {
        inherit (pkgs)
          bc
          cacert
          choose
          dust
          fd
          ffmpeg_7-full
          gum
          jq
          sd
          yt-dlp
          ;
      };
    }
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
    ls = "eza --oneline --icons auto";
    lt = "eza --oneline --reverse --sort=size --icons";
    ll = "eza --long --icons auto";
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
      if osConfig.nixpkgs.hostPlatform.isLinux then
        "nixos-rebuild switch --use-remote-sudo --flake $(readlink -f /etc/nixos)"
      else
        "sudo nix-darwin switch --flake $(readlink -f /etc/nixos)";

    update = ''
      __nixos_flake_update_func() {
        nix_user="$(whoami)"
        nix_host="$(hostname | sd '\\.local$' \'\')"
        flake_eval_path="$(perl -MCwd -e 'print Cwd::abs_path(shift)' "/etc/nixos")"
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
