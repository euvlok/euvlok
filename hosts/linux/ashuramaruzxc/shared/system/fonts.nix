{ pkgs, lib, ... }:
{
  fonts.packages = builtins.attrValues {
    inherit (pkgs)
      anonymousPro
      cascadia-code
      font-awesome
      ipafont
      liberation_ttf
      migmix
      monocraft
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      powerline-symbols
      recursive
      roboto
      roboto-mono
      source-code-pro
      source-han-sans
      terminus_font
      twemoji-color-font
      ubuntu-classic
      wqy_zenhei
      ;
    mplus = pkgs.mplus-outline-fonts.githubRelease;
    inherit (pkgs.nerd-fonts)
      agave
      fira-code
      hack
      inconsolata
      inconsolata-lgc
      iosevka
      iosevka-term
      jetbrains-mono
      meslo-lg
      monaspace
      noto
      recursive-mono
      ubuntu
      ubuntu-mono
      ubuntu-sans
      zed-mono
      ;
  };
  fonts.fontDir.enable = lib.mkIf pkgs.stdenvNoCC.isLinux true;
}
