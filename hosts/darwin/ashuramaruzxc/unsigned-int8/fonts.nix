{ pkgs, ... }:
{
  fonts.packages = builtins.attrValues {
    inherit (pkgs)
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      ;
    inherit (pkgs.nerd-fonts)
      hack
      meslo-lg
      ;
  };
}
