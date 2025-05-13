{
  pkgs,
  inputs,
  config,
  ...
}:
{
  home.packages = builtins.attrValues {
    # CLI
    dis = inputs.dis-source.packages.${config.nixpkgs.hostPlatform.system}.default;

    inherit (pkgs)
      appimage-run
      hugo
      octaveFull
      pdftk
      steam-run
      ;

    # Social
    inherit (pkgs)
      element-desktop
      mailspring
      nchat
      signal-desktop
      tdesktop
      ;

    # Sound
    inherit (pkgs) pavucontrol qpwgraph;

    # Torrent
    inherit (pkgs) qbittorrent;

    # Windows
    wineWow-stable = pkgs.wineWowPackages.stable;
    inherit (pkgs) winetricks;

    # Educational
    inherit (pkgs) libreoffice-qt-still zoom-us;

    # KDE Plasma
    inherit (pkgs.kdePackages)
      ark
      kclock
      kolourpaint
      okular
      ;

    inherit (pkgs)
      anki-bin
      bitwarden
      brave
      francis
      gImageReader
      gimp
      mullvad-vpn
      nekoray
      networkmanager-openvpn
      obs-studio
      treesheets
      ;
  };
}
