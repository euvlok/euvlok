{ pkgs, ... }:
{
  home.packages = builtins.attrValues {
    inherit (pkgs.unstable)
      # Base apps
      pavucontrol
      networkmanagerapplet
      desktop-file-utils
      unzip
      element-desktop
      hyprshot
      hyprcursor
      htop
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
      nixfmt
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
      nodejs
      # Misc productivity
      grim
      swappy
      slurp
      neofetch
      nitch
      thunderbird-bin
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
      slsk-batchdl
      nicotine-plus
      #kdenlive
      imagemagick
      gimp
      evince
      alsa-utils
      # Security
      nmap
      ghidra
      scanmem
      keepassxc
      ;
    inherit (pkgs.unstable.kdePackages)
      kalgebra
      kcalc
      ark
      okular
      ;
  };
}
