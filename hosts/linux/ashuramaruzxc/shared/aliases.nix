{ lib, ... }:
let
  aliases = {
    rebuild = lib.mkForce "nixos-rebuild test --use-remote-sudo --flake $(readlink -f /etc/nixos);nixos-rebuild switch --use-remote-sudo --flake $(readlink -f /etc/nixos)";
  };
in
{
  programs = lib.genAttrs [ "bash" "zsh" ] (_: {
    shellAliases = aliases;
  });
}
