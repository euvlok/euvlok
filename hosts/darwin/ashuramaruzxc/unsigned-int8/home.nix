{
  inputs,
  pkgs,
  lib,
  config,
  euvlok,
  pkgsUnstable,
  ...
}:
let
  release = builtins.fromJSON (config.system.darwinRelease);

  commonImports = [
    { home.stateVersion = "25.05"; }
    inputs.catppuccin-trivial.homeModules.catppuccin
    ../../../../modules/hm
    ../../../hm/ashuramaruzxc/starship.nix
    ../../../hm/ashuramaruzxc/aliases.nix
  ];

  catppuccinConfig = {
    catppuccin = {
      enable = true;
      flavor = "mocha";
      accent = "flamingo";
    };
  };

  ashuramaruHmConfig = {
    hm = {
      fastfetch.enable = true;
      firefox.defaultSearchEngine = "kagi";
      firefox.enable = true;
      firefox.floorp.enable = true;
      helix.enable = true;
      mpv.enable = true;
      nh.enable = true;
      nixcord.enable = true;
      nvf.enable = true;
      vscode.enable = true;
      # yazi.enable = true;
      zellij.enable = true;
    };
  };

  ashuramaruImports = [
    ../../../hm/ashuramaruzxc/firefox.nix
    ../../../hm/ashuramaruzxc/git.nix
    ../../../hm/ashuramaruzxc/nixcord.nix
    ../../../hm/ashuramaruzxc/ssh.nix
    ../../../hm/ashuramaruzxc/nushell.nix
    ../../../hm/ashuramaruzxc/vscode.nix
  ];

  macosPackages = builtins.attrValues {
    inherit (pkgs)
      alt-tab-macos
      hidden-bar
      rectangle
      raycast
      iina
      iterm2
      ;
  };

  socialPackages = builtins.attrValues {
    inherit (pkgs) signal-desktop-bin materialgram;
  };

  multimediaPackages = builtins.attrValues {
    inherit (pkgs)
      qbittorrent
      anki-bin
      audacity
      gimp
      inkscape
      yubikey-manager
      ;
  };

  gamingPackages = builtins.attrValues {
    inherit (pkgs)
      winetricks
      ryubing
      prismlauncher
      chiaki
      duckstation-bin
      ;
    inherit (pkgs.jetbrains) dataspell datagrip;
    pcsx2-bin = pkgs.pcsx2-bin.overrideAttrs (oldAttrs: {
      meta = lib.recursiveUpdate oldAttrs.meta { platforms = lib.platforms.darwin; };
    });
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
        "ini"
        "nixidea"
        "rainbow-brackets"
      ];
    in
    builtins.attrValues {
      riderWithPlugins = addPlugins rider (commonPlugins ++ [ "python-community-edition" ]);
      clionWithPlugins = addPlugins clion (commonPlugins ++ [ "rust" ]);
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

  allPackages =
    macosPackages ++ socialPackages ++ multimediaPackages ++ gamingPackages ++ jetbrainsPackages;
in
{
  imports = [ inputs.home-manager-ashuramaruzxc.darwinModules.home-manager ];

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
      { home.packages = allPackages; }
      (
        { config, ... }:
        {
          home.file."Documents/development/catppuccin/catppuccin-userstyles.json".source =
            (pkgs.callPackage ../../../../pkgs/catppuccin-userstyles.nix {
              inherit (config.catppuccin) accent flavor;
            }).outPath
            + "/dist/import.json";
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
              pinentry = pkgs.pinentry_mac;
            };
          };
          btop.enable = true;
        };
      }
    ];
}
