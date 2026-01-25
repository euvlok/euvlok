{ pkgs }:
let
  categories = {
    important = builtins.attrValues {
      inherit (pkgs.unstable)
        keepassxc
        bitwarden-desktop
        thunderbird-bin
        ;
    };

    multimedia = builtins.attrValues {
      inherit (pkgs)
        nicotine-plus
        qbittorrent
        quodlibet-full
        tenacity
        vlc
        youtube-music
        ;
      inherit (pkgs.kdePackages)
        k3b
        kamera
        ;
    };

    productivity = builtins.attrValues {
      inherit (pkgs)
        anki
        gImageReader
        libreoffice-qt6-fresh
        obsidian
        octaveFull
        pdftk
        treesheets
        ;
      inherit (pkgs.kdePackages) francis;
    };

    social = builtins.attrValues {
      inherit (pkgs)
        dino
        materialgram
        nextcloud-client
        signal-desktop
        ;
    };

    networking = builtins.attrValues {
      inherit (pkgs)
        mullvad-vpn
        throne
        openvpn
        protonvpn-gui
        udptunnel
        v2raya
        ;
    };

    audio = builtins.attrValues { inherit (pkgs) helvum pavucontrol qpwgraph; };

    gaming = builtins.attrValues {
      inherit (pkgs.unstable) osu-lazer-bin;
      inherit (pkgs)
        bottles
        cemu
        chiaki
        dolphin-emu
        flycast
        gogdl
        goverlay
        heroic
        lutris
        mangohud
        mgba
        pcsx2
        ppsspp
        prismlauncher
        ryubing
        shadps4
        xemu
        ;
    };

    development = builtins.attrValues {
      inherit (pkgs.unstable)
        android-studio
        nixd
        ;
      inherit (pkgs.unstable.jetbrains) dataspell datagrip;
    };

    jetbrains = [
      pkgs.unstable.jetbrains.rider
      pkgs.unstable.jetbrains.clion
      pkgs.unstable.jetbrains.idea
    ];

    nemo = [
      (pkgs.nemo-with-extensions.override {
        extensions = builtins.attrValues {
          inherit (pkgs)
            folder-color-switcher
            nemo-emblems
            nemo-fileroller
            nemo-python
            nemo-qml-plugin-dbus
            ;
        };
      })
    ];
  };

  mkPackages =
    names:
    let
      fetch =
        name:
        if builtins.hasAttr name categories then
          categories.${name}
        else
          throw "home-packages: category '${name}' not defined";
    in
    builtins.concatLists (map fetch names);
in
{
  inherit categories mkPackages;
}
