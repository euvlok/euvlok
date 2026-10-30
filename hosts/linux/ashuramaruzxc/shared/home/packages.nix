{
  pkgs,
  lib,
  jetbrainsPlugins,
}:
let
  jetbrainsPackages = import ../../../../hm/ashuramaruzxc/jetbrains.nix {
    inherit jetbrainsPlugins;
    pkgs = pkgs.unstable;
  };

  categories = {
    audio = lib.attrsets.attrValues { inherit (pkgs) crosspipe pavucontrol qpwgraph; };

    development = lib.attrsets.attrValues {
      inherit (pkgs.unstable)
        android-studio
        nixd
        ;
      inherit (jetbrainsPackages) dataspell;
    };

    gaming = lib.attrsets.attrValues {
      inherit (pkgs.unstable)
        cemu
        chiaki
        dolphin-emu
        eden
        flycast
        gogdl
        goverlay
        heroic
        mangohud
        mgba
        osu-lazer-bin
        pcsx2
        ppsspp
        prismlauncher
        rpcs3
        ryubing
        shadps4
        xemu
        ;
    };

    important =
      lib.attrsets.attrValues {
        inherit (pkgs.unstable)
          bitwarden-desktop
          keepassxc
          ;
      }
      ++ [
        (
          if pkgs.stdenvNoCC.hostPlatform.isx86_64 then
            pkgs.unstable.thunderbird-bin
          else
            pkgs.unstable.thunderbird
        )
      ];

    jetbrains = [
      jetbrainsPackages.clion
      jetbrainsPackages.idea
      jetbrainsPackages.rider
    ];

    multimedia = lib.attrsets.attrValues {
      inherit (pkgs)
        nicotine-plus
        pear-desktop
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

    networking = builtins.attrValues {
      inherit (pkgs)
        openvpn
        proton-vpn
        throne
        udptunnel
        v2raya
        ;
    };

    productivity = lib.attrsets.attrValues {
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

    social = lib.attrsets.attrValues {
      inherit (pkgs.unstable)
        dino
        nextcloud-client
        signal-desktop
        ;
      inherit (pkgs.stable) telegram-desktop;
    };
  };

  mkPackages = lib.lists.concatMap (
    name: categories.${name} or (throw "home-packages: category '${name}' not defined")
  );
in
{
  inherit categories mkPackages;
}
