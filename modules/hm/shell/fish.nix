{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.hm.fish.enable = lib.mkEnableOption "Fish";

  config = lib.mkIf config.hm.fish.enable {
    programs.fish.enable = true;
    programs.fish.plugins = [
      {
        name = "fzf.fish";
        src = pkgs.fetchFromGitHub {
          owner = "PatrickF1";
          repo = "fzf.fish";
          rev = "8920367cf85eee5218cc25a11e209d46e2591e7a";
          hash = "sha256-T8KYLA/r/gOKvAivKRoeqIwE2pINlxFQtZJHpOy9GMM=";
        };
      }
      {
        name = "replay.fish";
        src = pkgs.fetchFromGitHub {
          owner = "jorgebucaran";
          repo = "replay.fish";
          rev = "d2ecacd3fe7126e822ce8918389f3ad93b14c86c";
          hash = "sha256-TzQ97h9tBRUg+A7DSKeTBWLQuThicbu19DHMwkmUXdg=";
        };
      }
      {
        name = "sponge";
        src = pkgs.fetchFromGitHub {
          owner = "meaningful-ooo";
          repo = "sponge";
          rev = "384299545104d5256648cee9d8b117aaa9a6d7be";
          hash = "sha256-MdcZUDRtNJdiyo2l9o5ma7nAX84xEJbGFhAVhK+Zm1w=";
        };
      }
    ];
    programs.fish.shellAliases = {

      nix-build-file = ''
        function nix-build-file --description 'Build a Nix file using callPackage'
            set file "$argv[1]"
            # Default args to an empty attribute set string
            set args "{}"

            # Check if args argument is provided
            if test -n "$argv[2]"
                set args "$argv[2]"
            end

            # Construct the Nix expression string. Use double quotes for variable expansion.
            # Be careful with nested quotes and escaping if the args string itself contains special chars.
            set nix_expr "with import (builtins.getFlake 'nixpkgs') {}; callPackage ./$file $args"
            nix-build -E "$nix_expr"
        end
      '';

      rebuild = ''
        function rebuild --description 'Rebuild system configuration (NixOS or Darwin)'
            set uname_str (uname -s)
            if string match -q -i "*linux*" -- "$uname_str"
                nixos-rebuild switch --use-remote-sudo --flake /etc/nixos/ $argv
            else
                darwin-rebuild switch --flake /etc/nixos/ $argv
            end
        end
      '';

      update = ''
        function update --description 'Update personal inputs'
            set nix_user (whoami)
            set raw_host (hostname)
            set uname_str (uname -s)
            if test (string match -r -i darwin $uname_str)
                set nix_host (string replace -r '\.local$' \'\' -- $raw_host)
                set flake_attr "darwinConfigurations"
            else
                set nix_host $raw_host
                set flake_attr "nixosConfigurations"
            end
            set flake_path /etc/nixos
            set flake_eval_path /etc/nixos
            set nix_user_escaped (string replace '"' '\\"' -- $nix_user)
            set nix_host_escaped (string replace '"' '\\"' -- $nix_host)
            set nix_expr "let
          flake = builtins.getFlake \"$flake_eval_path\";
          host = flake.$flake_attr.\"$nix_host_escaped\";
          user = \"$nix_user_escaped\";
        in
          host.config.home-manager.users.\''${user}.programs.git.userName"
            set github_username (
                nix eval --raw --impure --expr "$nix_expr" | tr '[:upper:]' '[:lower:]' | string trim
            )
            set matching_inputs (
                nix eval --json --impure --expr "(builtins.attrNames (builtins.getFlake \"$flake_eval_path\").inputs)" \
                | jq -r --arg pattern "-$github_username" '.[] | select(endswith($pattern))' | string join ' '
            )
            nix flake update $matching_inputs --flake "$flake_path"
        end
      '';
    };
  };
}
