{ pkgs }:
let
  categories = {
    important = builtins.attrValues {
      inherit (pkgs.unstable)
        keepassxc
        bitwarden-desktop
        thunderbird
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
        nekoray
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

    jetbrains =
      let
        inherit (pkgs.unstable.jetbrains.plugins) addPlugins;
        inherit (pkgs.unstable.jetbrains) rider clion idea;
        commonPlugins = [
          "better-direnv"
          "catppuccin-icons"
          "catppuccin-theme"
          "csv-editor"
          "docker"
          "gittoolbox"
          "graphql"
          "indent-rainbow"
          "ini"
          "nixidea"
          "rainbow-brackets"
          "rainbow-csv"
          "toml"
          "vscode-keymap"
        ];
      in
      builtins.attrValues {
        riderWithPlugins = addPlugins rider (commonPlugins ++ [ "python-community-edition" ]);
        clionWithPlugins = addPlugins clion (
          commonPlugins
          ++ [
            "rust"
            "python-community-edition"
          ]
        );
        ideaUltimateWithPlugins = addPlugins idea-ultimate (
          commonPlugins
          ++ [
            "go"
            "minecraft-development"
            "python"
            "rust"
            "scala"
          ]
        );
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
