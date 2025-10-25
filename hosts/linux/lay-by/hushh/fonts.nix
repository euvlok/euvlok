{ pkgs, ... }:
{
  fonts = {
    enableDefaultPackages = true;
    fontDir.enable = true;
    packages = builtins.attrValues {
      inherit (pkgs)
        dina-font
        fira-code-symbols
        noto-fonts-cjk-sans
        noto-fonts-emoji
        sarasa-gothic
        twemoji-color-font
        vegur
        ;
      inherit (pkgs.nerd-fonts)
        fira-code
        fira-mono
        iosevka
        liberation
        meslo-lg
        monaspace
        noto
        proggy-clean-tt
        victor-mono
        ;
    };

    fontconfig.defaultFonts = {
      monospace = [
        "Iosevka Nerd Font Mono"
        "Noto Color Emoji"
      ];
      sansSerif = [
        "Vegur"
        "Noto Color Emoji"
      ];
      serif = [
        "Vegur"
        "Noto Color Emoji"
      ];
      emoji = [ "Twitter Color Emoji" ];
    };
  };
}
