{
  inputs,
  lib,
  config,
  eulib,
  pkgsUnstable,
  ...
}:
{
  home.packages = builtins.attrValues {
    inherit (pkgsUnstable)
      # Base apps
      pavucontrol
      vesktop
      networkmanagerapplet
      desktop-file-utils
      unzip
      element-desktop
      hyprshot
      hyprcursor
      htop
      alac
      # Gaming
      protontricks
      libnvidia-container
      lutris
      wine
      winetricks
      r2modman
      prismlauncher
      # Development
      gnumake
      nixfmt-rfc-style
      meson
      cmake
      font-manager
      # nim
      nim
      nimble
      nimlsp
      nimlangserver
      nil
      devenv
      nix-search
      # Misc productivity
      grim
      swappy
      slurp
      neofetch
      nitch
      thunderbird
      libreoffice
      p7zip
      #_7zz
      file
      wlsunset
      killall
      piper

      # Media
      #davinci-resolve
      #blender
      playerctl
      yt-dlp
      deluge-gtk
      #kdenlive
      imagemagick
      gimp
      evince
      alsa-utils
      # Security
      nmap
      ghidra
      scanmem
      ;
    inherit (pkgsUnstable.kdePackages)
      kalgebra
      kcalc
      ark
      okular
      ;
  };
}
