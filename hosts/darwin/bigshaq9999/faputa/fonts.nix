{ pkgs, ... }:
{
  fonts.packages = builtins.attrValues {
    inherit (pkgs.nerd-fonts)
      jetbrains-mono
      monaspace
      noto
      hack
      ;
  };
}
