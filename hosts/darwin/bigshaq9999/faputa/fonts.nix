{ lib, pkgs, ... }:
{
  fonts.packages = lib.attrsets.attrValues {
    inherit (pkgs.nerd-fonts)
      jetbrains-mono
      monaspace
      noto
      hack
      ;
  };
}
