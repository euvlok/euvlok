{
  inputs,
  config,
  pkgs,
  eulib,
  pkgsUnstable,
  ...
}:
let
  release = builtins.fromJSON (config.system.nixos.release);

  commonImports = [
    { home.stateVersion = "25.05"; }
    ../../../../modules/hm
    ../../../../pkgs/catppuccin-gtk.nix
    ../../../hm/ashuramaruzxc/helix.nix
    ../../../hm/ashuramaruzxc/aliases.nix
    ../../../hm/ashuramaruzxc/starship.nix
    ../shared/aliases.nix
    inputs.catppuccin-trivial.homeModules.catppuccin
  ];

  catppuccinConfig =
    { osConfig, ... }:
    {
      catppuccin = { inherit (osConfig.catppuccin) enable accent flavor; };
    };

  rootHmConfig = {
    hm = {
      bash.enable = true;
      direnv.enable = true;
      fzf.enable = true;
      helix.enable = true;
      nh.enable = true;
      zellij.enable = true;
      zsh.enable = true;
    };
  };

  ashuramaruHmConfig = {
    hm = {
      chromium.enable = true;
      fastfetch.enable = true;
      firefox = {
        enable = true;
        floorp.enable = true;
        zen-browser.enable = true;
        defaultSearchEngine = "kagi";
      };
      ghostty.enable = true;
      helix.enable = true;
      mpv.enable = true;
      nh.enable = true;
      nixcord.enable = true;
      nushell.enable = true;
      vscode.enable = true;
      yazi.enable = true;
      zed-editor.enable = true;
      zellij.enable = true;
      zsh.enable = true;
      languages = {
        cpp.enable = true;
        # csharp.enable = true;
        # csharp.version = "8";
        go.enable = true;
        haskell.enable = true;
        java.enable = true;
        java.version = "17";
        javascript.enable = true;
        kotlin.enable = true;
        lisp.enable = true;
        lua.enable = true;
        python.enable = true;
        ruby.enable = true;
        rust.enable = true;
        scala.enable = true;
      };
    };
  };

  ashuramaruImports = [
    ../../../hm/ashuramaruzxc/chrome.nix
    ../../../hm/ashuramaruzxc/dconf.nix
    ../../../hm/ashuramaruzxc/firefox.nix
    ../../../hm/ashuramaruzxc/flatpak.nix
    ../../../hm/ashuramaruzxc/git.nix
    ../../../hm/ashuramaruzxc/graphics.nix
    ../../../hm/ashuramaruzxc/nixcord.nix
    ../../../hm/ashuramaruzxc/nushell.nix
    ../../../hm/ashuramaruzxc/ssh.nix
    ../../../hm/ashuramaruzxc/vscode.nix
    ../../../linux/shared/protonmail-bridge.nix
  ];

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
    inherit (pkgs.kdePackages)
      k3b
      kamera
      ;
  };

  productivityPackages = builtins.attrValues {
    inherit (pkgs)
      anki
      francis
      gImageReader
      libreoffice-qt6-fresh
      obsidian
      octaveFull
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
      zoom-us
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

  gamingPackages = builtins.attrValues {
    inherit (pkgsUnstable) osu-lazer-bin;
    inherit (pkgs)
      bottles
      cemu
      chiaki
      dolphin-emu
      duckstation
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
      ryujinx
      shadps4
      xemu
      ;
  };
  developmentPackages = builtins.attrValues {
    inherit (pkgsUnstable) android-studio nixd;
    inherit (pkgsUnstable.jetbrains) dataspell datagrip;
  };

  jetbrainsPackages =
    let
      inherit (pkgsUnstable.jetbrains.plugins) addPlugins;
      inherit (pkgsUnstable.jetbrains) rider clion idea-ultimate;
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

  allPackages =
    importantPackages
    ++ multimediaPackages
    ++ productivityPackages
    ++ socialPackages
    ++ networkingPackages
    ++ audioPackages
    ++ gamingPackages
    ++ developmentPackages
    ++ jetbrainsPackages
    ++ nemoPackage;
in
{
  imports = [ inputs.home-manager-ashuramaruzxc.nixosModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "bak";
    extraSpecialArgs = {
      inherit
        inputs
        release
        eulib
        pkgsUnstable
        ;
    };
  };

  home-manager.users.root.imports = commonImports ++ [
    catppuccinConfig
    rootHmConfig
  ];

  home-manager.users.ashuramaru.imports =
    commonImports
    ++ [
      catppuccinConfig
      inputs.sops-nix-trivial.homeManagerModules.sops
      {
        sops = {
          age.keyFile = "$HOME/.config/sops/age/keys.txt";
          defaultSopsFile = ../../../../secrets/ashuramaruzxc_unsigned-int32.yaml;
        };
      }
    ]
    ++ ashuramaruImports
    ++ [
      ashuramaruHmConfig
      { services.protonmail-bridge.enable = true; }
      { home.packages = allPackages; }
      (
        {
          inputs,
          config,
          lib,
          osConfig,
          ...
        }:
        {
          # doesn't work with cudaEnable = true;
          home.packages = builtins.attrValues {
            inherit (inputs.nixpkgs.legacyPackages.${osConfig.nixpkgs.hostPlatform.system}) rpcs3;
          };
          home.pointerCursor = {
            enable = true;
            name = "touhou-reimu";
            package = inputs.anime-cursors-source.packages.${osConfig.nixpkgs.hostPlatform.system}.cursors;
            size = 32;
            gtk.enable = true;
            x11 = {
              enable = true;
              defaultCursor = "touhou-reimu";
            };
          };
          gtk = {
            enable = true;
            iconTheme = {
              name = lib.mkForce "breeze-dark";
              package = lib.mkForce pkgs.kdePackages.breeze-icons;
            };
          };
          catppuccin.i-still-want-to-use-the-archived-gtk-theme-because-it-works-better-than-everything-else = {
            enable = true;
            inherit (osConfig.catppuccin) accent flavor;
            size = "standard";
            tweaks = [
              "rimless"
              "normal"
            ];
          };
          home.sessionVariables = {
            GTK_CSD = "0";
            GO_PATH = "${config.home.homeDirectory}/.go";
            GEM_HOME = "${config.home.homeDirectory}/.gems";
            GEM_PATH = "${config.home.homeDirectory}/.gems";
          };
          services.easyeffects.enable = true;
        }
      )
      {
        programs = {
          rbw = {
            enable = true;
            settings = {
              email = "ashuramaru@tenjin-dk.com";
              base_url = "https://bitwarden.tenjin-dk.com";
              lock_timeout = 600;
              pinentry = pkgs.pinentry-qt;
            };
          };
          btop.enable = true;
        };
      }
    ];
}
