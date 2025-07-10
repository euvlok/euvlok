{ lib, ... }:
let
  aliases = {
    rebuild = lib.mkForce "nixos-rebuild test --use-remote-sudo --flake $(readlink -f /etc/nixos);nixos-rebuild switch --use-remote-sudo --flake $(readlink -f /etc/nixos)";
    vi = "hx";
    vim = "hx";
    nvim = "hx";
  };
in
{
  programs = lib.genAttrs [ "bash" "zsh" ] (_: {
    shellAliases = aliases;
  });
}
