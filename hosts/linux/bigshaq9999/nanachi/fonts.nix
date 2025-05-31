{ pkgs, ... }:
{
  fonts = {
    fontDir.enable = true;
    enableDefaultPackages = true;
    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [ "Hack" ];
        emoji = [ "Twitter Color Emoji" ];
      };
    };
    packages = builtins.attrValues {
      inherit (pkgs)
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-emoji
        twitter-color-emoji
        ;
      inherit (pkgs.nerd-fonts)
        jetbrains-mono
        ;
    };
  };
}
