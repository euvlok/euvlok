{ lib, ... }:
{
  euvlok.home.chromium = {
    enable = true;
    browser = lib.modules.mkDefault "helium-browser";
    extraExtensions = import ./extensions.nix;
  };
}
