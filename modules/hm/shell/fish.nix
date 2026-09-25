{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.modules.mkIf config.programs.fish.enable {
    programs.fish.plugins = [
      {
        name = "fzf.fish";
        src = pkgs.fishPlugins.fzf-fish;
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
        src = pkgs.fishPlugins.sponge;
      }
    ];
    programs.fish.functions = {
      nix-build-file = {
        description = "Build a Nix file using callPackage";
        body = ''
          set file "$argv[1]"
          set args "{}"

          if test -n "$argv[2]"
              set args "$argv[2]"
          end

          set expanded_file (realpath "$file")
          nix-build -E "with import <nixpkgs> {}; callPackage $expanded_file $args"
        '';
      };

      clean-roots = {
        description = "Clean up nix store roots";
        body = ''
          nix-store --gc --print-roots \
          | rg --no-filename -v '^(/nix/var|/run/\w+-system|\{|/proc)' \
          | rg --no-filename -v 'home-manager|flake-registry\.json' \
          | rg --no-filename -o -r '$1' '^(\S+)' \
          | xargs -L1 unlink
        '';
      };

      xdg-data-dirs = {
        description = "List XDG data directories with indices";
        body = ''
          echo "$XDG_DATA_DIRS" | tr ':' '\n' | nl -v 0
        '';
      };

      rebuild = {
        description = "Rebuild system configuration (NixOS or Darwin)";
        body = ''
          set uname_str (uname -s)
          if string match -q -i "*linux*" -- "$uname_str"
              nixos-rebuild switch --use-remote-sudo --flake /etc/nixos/ $argv
          else
              darwin-rebuild switch --flake /etc/nixos/ $argv
          end
        '';
      };

      update = {
        description = "Update personal inputs";
        body = ''
          set nix_user (whoami)
          set raw_host (hostname)
          set uname_str (uname -s)

          if string match -q -i "*darwin*" -- "$uname_str"
              set nix_host (string replace -r '\.local$' "" -- "$raw_host")
              set flake_attr "darwinConfigurations"
          else
              set nix_host "$raw_host"
              set flake_attr "nixosConfigurations"
          end

          set flake_path (readlink -f "/etc/nixos")
          set nix_user_escaped (string replace '"' '\\"' -- "$nix_user")
          set nix_host_escaped (string replace '"' '\\"' -- "$nix_host")

          set nix_expr "let flake = builtins.getFlake \"$flake_path\"; host = flake.$flake_attr.\"$nix_host_escaped\"; user = \"$nix_user_escaped\"; in host.config.home-manager.users.\''${user}.programs.git.settings.user.name"

          set github_username (nix eval --raw --impure --expr "$nix_expr" | string lower | string trim)

          set matching_inputs (nix eval --json --impure --expr "(builtins.attrNames (builtins.getFlake \"$flake_path\").inputs)" | jq -r --arg pattern "-$github_username" '.[] | select(endswith($pattern))' | string join ' ')
          nix flake update $matching_inputs --flake "$flake_path"
        '';
      };
    };
  };
}
