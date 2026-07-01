{ pkgs }:
let
  categories = {
    audio = builtins.attrValues { inherit (pkgs) crosspipe pavucontrol qpwgraph; };

    development = builtins.attrValues {
      inherit (pkgs.unstable)
        android-studio
        nixd
        ;
      inherit (pkgs.unstable.jetbrains) datagrip dataspell;
    };

    gaming = builtins.attrValues {
      inherit (pkgs.unstable) osu-lazer-bin;
      inherit (pkgs)
        # bottles
        cemu
        chiaki
        dolphin-emu
        eden
        flycast
        gogdl
        goverlay
        # heroic
        mangohud
        mgba
        pcsx2
        ppsspp
        prismlauncher
        rpcs3
        ryubing
        shadps4
        xemu
        ;
    };

    important = builtins.attrValues {
      inherit (pkgs.unstable)
        bitwarden-desktop
        keepassxc
        thunderbird
        ;
    };

    jetbrains = [
      pkgs.unstable.jetbrains.clion
      pkgs.unstable.jetbrains.idea
      pkgs.unstable.jetbrains.rider
    ];

    multimedia = builtins.attrValues {
      inherit (pkgs)
        nicotine-plus
        # pear-desktop
        qbittorrent
        quodlibet-full
        tenacity
        vlc
        ;
      inherit (pkgs.unstable.kdePackages)
        k3b
        kamera
        ;
    };

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

    networking = builtins.attrValues {
      inherit (pkgs)
        mullvad-vpn
        openvpn
        proton-vpn
        throne
        udptunnel
        v2raya
        ;
    };

    productivity = builtins.attrValues {
      inherit (pkgs.unstable)
        anki
        gImageReader
        obsidian
        pdftk
        treesheets
        whisper-cpp
        ;
      inherit (pkgs.unstable.kdePackages) francis;
    };

    social = builtins.attrValues {
      inherit (pkgs.unstable)
        dino
        materialgram
        nextcloud-client
        # signal-desktop
        ;
    };
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
