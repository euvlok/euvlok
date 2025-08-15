{
  inputs,
  config,
  pkgs,
  euvlok,
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
      nushell.enable = true;
      yazi.enable = true;
      zellij.enable = true;
      zsh.enable = true;
    };
  };

  ashuramaruImports = [
    ../../../hm/ashuramaruzxc/chrome.nix
    ../../../hm/ashuramaruzxc/dconf.nix
    ../../../hm/ashuramaruzxc/firefox.nix
    ../../../hm/ashuramaruzxc/flatpak.nix
    ../../../hm/ashuramaruzxc/git.nix
    ../../../hm/ashuramaruzxc/nixcord.nix
    ../../../hm/ashuramaruzxc/nushell.nix
    ../../../hm/ashuramaruzxc/ssh.nix
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

  allPackages =
    importantPackages
    ++ multimediaPackages
    ++ productivityPackages
    ++ socialPackages
    ++ networkingPackages
    ++ audioPackages
    # ++ jetbrainsPackages
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
        euvlok
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
      # {
      #   sops = {
      #     age.keyFile = "$HOME/.config/sops/age/keys.txt";
      #     defaultSopsFile = ../../../../secrets/ashuramaruzxc_unsigned-int32.yaml;
      #   };
      # }
    ]
    ++ ashuramaruImports
    ++ [
      ashuramaruHmConfig
      { services.protonmail-bridge.enable = true; }
      { home.packages = allPackages; }
      (
        { inputs, osConfig, ... }:
        {
          # doesn't work with cudaEnable = true;
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
      {
        gtk = {
          enable = true;
          iconTheme = {
            name = "breeze-dark";
            package = pkgs.kdePackages.breeze-icons;
          };
        };
        catppuccin.gtk.enable = true;
        catppuccin.gtk.gnomeShellTheme = true;
        catppuccin.gtk.tweaks = [
          "rimless"
          "normal"
        ];
        home.sessionVariables = {
          GTK_CSD = "0";
        };
        services.easyeffects.enable = true;
      }
    ];
}
