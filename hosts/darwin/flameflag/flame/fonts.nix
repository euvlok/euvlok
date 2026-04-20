{ pkgs, ... }:
{
  fonts.packages = builtins.attrValues {
    inherit (pkgs.nerd-fonts)
      ubuntu-mono
      fira-code
      monaspace
      noto
      ;
  };
}
