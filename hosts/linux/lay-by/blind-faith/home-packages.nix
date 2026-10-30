{ lib, pkgs, ... }:
{

  home.packages = lib.attrsets.attrValues {
    inherit (pkgs) corefonts photocraft;
    inherit (pkgs.unstable)
      # Base apps
      pavucontrol
      networkmanagerapplet
      element-desktop
      hyprshot
      hyprcursor
      htop
      mission-center
      ;
    inherit (pkgs.unstable)
      # Gaming
      protontricks
      libnvidia-container
      wine
      winetricks
      prismlauncher
      ;
    inherit (pkgs.unstable)
      # Development
      vscode-fhs
      lmstudio
      gnumake
      nixfmt
      meson
      cmake
      ;
    inherit (pkgs.unstable)
      # nim
      nim
      nimble
      nimlsp
      nimlangserver
      nil
      nodejs
      ;
    inherit (pkgs.unstable)
      # Misc productivity
      grim
      swappy
      slurp
      nitch
      thunderbird-bin
      telegram-desktop
      #freecad
      #libreoffice
      wlsunset
      piper
      ;
    inherit (pkgs.unstable)
      # Media
      # davinci-resolve
      # blender
      playerctl
      feishin
      deluge-gtk
      slsk-batchdl
      nicotine-plus
      #kdenlive
      imagemagick
      evince
      alsa-utils
      ;
    inherit (pkgs.unstable)
      # Security
      nmap
      keepassxc
      scanmem
      ;
    inherit (pkgs.unstable.kdePackages)
      kcalc
      ark
      okular
      ;
  };
}
