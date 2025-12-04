{ lib, ... }:
let
  aliases = {
    rebuild = lib.mkForce "nixos-rebuild test --use-remote-sudo --flake $(readlink -f /etc/nixos);nixos-rebuild switch --use-remote-sudo --flake $(readlink -f /etc/nixos)";
    xdg-data-dirs = "echo -e $XDG_DATA_DIRS | tr ':' '\n' | nl | sort";
  };
in
{
  programs = lib.genAttrs [ "bash" "zsh" ] (_: {
    shellAliases = aliases;
  });
}
