{ lib, ... }:
{
  programs.zoxide.enable = lib.mkDefault true;
}
