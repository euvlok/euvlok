{ lib, ... }:
{
  programs.direnv.enable = lib.modules.mkDefault true;
  programs.direnv.nix-direnv.enable = true;
}
