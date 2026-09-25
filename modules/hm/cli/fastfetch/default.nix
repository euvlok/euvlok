{ lib, ... }:
{
  programs.fastfetch.settings = lib.trivial.importJSON ./settings.json;
}
