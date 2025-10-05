{ pkgs, ... }:
let
  importantPackages = builtins.attrValues {
    inherit (pkgs) keepassxc bitwarden thunderbird;
  };

  multimediaPackages = builtins.attrValues {
    inherit (pkgs)
      nicotine-plus
      qbittorrent
      quodlibet-full
      tenacity
      vlc
      youtube-music
      ;
    inherit (pkgs.kdePackages) k3b;
  };

  productivityPackages = builtins.attrValues {
    inherit (pkgs)
      anki
      gImageReader
      libreoffice-qt6-fresh
      pdftk
      treesheets
      ;
  };

  socialPackages = builtins.attrValues {
    inherit (pkgs)
      dino
      element-desktop
      materialgram
      nextcloud-client
      protonmail-bridge-gui
      signal-desktop
      ;
  };

  networkingPackages = builtins.attrValues {
    inherit (pkgs)
      mullvad-vpn
      nekoray
      openvpn
      protonvpn-cli
      protonvpn-gui
      udptunnel
      v2raya
      ;
  };

  audioPackages = builtins.attrValues {
    inherit (pkgs)
      feather
      helvum
      pavucontrol
      qpwgraph
      ;
  };

  jetbrainsPackages =
    let
      inherit (pkgs.jetbrains.plugins) addPlugins;
      inherit (pkgs.jetbrains) rider clion idea-ultimate;
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

  nemoPackage = [
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
in
{
  home-manager.users.ashuramaru.imports = [
    {
      home.packages =
        importantPackages
        ++ multimediaPackages
        ++ productivityPackages
        ++ socialPackages
        ++ networkingPackages
        ++ audioPackages
        ++ nemoPackage;
    }
  ];
}
