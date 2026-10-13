{ lib, ... }:
{
  programs.zoxide.enable = lib.modules.mkDefault true;
}
