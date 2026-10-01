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
        description = "Update shared flake inputs";
        body = ''
          nix flake update --flake (path resolve /etc/nixos) $argv
        '';
      };

      update-users = {
        description = "Update contributor flake inputs";
        body = ''
          set flake_path (path resolve /etc/nixos)
          nix flake update --flake "$flake_path/flake-modules/users" $argv
        '';
      };
    };
  };
}
