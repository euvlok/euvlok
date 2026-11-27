{
  pkgs,
  lib,
}:
let
  categories = {
    audio = lib.attrsets.attrValues { inherit (pkgs) crosspipe pavucontrol qpwgraph; };

    development = lib.attrsets.attrValues {
      inherit (pkgs) android-studio nixd;
    };

    gaming = lib.attrsets.attrValues {
      inherit (pkgs)
        cemu
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
        inherit (pkgs) bitwarden-desktop keepassxc;
      }
      ++ [
        (if pkgs.stdenvNoCC.hostPlatform.isx86_64 then pkgs.thunderbird-bin else pkgs.thunderbird)
      ];

    jetbrains = [
      pkgs.jetbrains.clion
      pkgs.jetbrains.idea
      pkgs.jetbrains.rider
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
      inherit (pkgs.kdePackages) k3b kamera;
    };

    networking = lib.attrsets.attrValues {
      inherit (pkgs)
        openvpn
        proton-vpn
        throne
        udptunnel
        v2raya
        ;
    };

    productivity = lib.attrsets.attrValues {
      inherit (pkgs)
        anki
        euro-office-desktopeditors
        gImageReader
        obsidian
        pdftk
        treesheets
        whisper-cpp
        ;
      inherit (pkgs.kdePackages) francis;
    };

    social = lib.attrsets.attrValues {
      inherit (pkgs)
        dino
        nextcloud-client
        signal-desktop
        ;
      inherit (pkgs.stable) telegram-desktop;
    };
  };

  mkPackages = lib.lists.concatMap (
    name:
    lib.attrsets.attrByPath [ name ] (throw "home-packages: category '${name}' not defined") categories
  );
in
{
  inherit categories mkPackages;
}
