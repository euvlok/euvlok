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
      ;
    inherit (pkgs.unstable)
      # Gaming
      protontricks
      libnvidia-container
      lutris
      wine
      winetricks
      r2modman
      prismlauncher
      ;
    inherit (pkgs.unstable)
      # Development
      gnumake
      nixfmt
      meson
      cmake
      font-manager
      python3


      # nim
      nim
      nimble
      nimlsp
      nimlangserver
      nil
      devenv
      nix-search
      nodejs
      ;
    inherit (pkgs.unstable.python313Packages)
      pip
      ;
    inherit (pkgs.unstable)
      # Misc productivity
      grim
      swappy
      slurp
      nitch
      thunderbird-bin
      libreoffice
      p7zip
      # _7zz
      file
      wlsunset
      killall
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
      gimp
      evince
      alsa-utils
      ;
    inherit (pkgs.unstable)
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
