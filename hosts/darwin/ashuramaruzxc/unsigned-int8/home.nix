{
  inputs,
  pkgs,
  config,
  ...
}:
let
  release = builtins.fromJSON (config.system.darwinRelease);
in
{
  imports = [ inputs.home-manager-ashuramaruzxc.darwinModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = ".bak";
    users.ashuramaru =
      { config, ... }:
      {
        imports = [
          { home.stateVersion = "25.05"; }
          inputs.catppuccin.homeModules.catppuccin
          {
            catppuccin = {
              enable = true;
              flavor = "mocha";
              accent = "rosewater";
            };
          }

          ../../../hm/ashuramaruzxc/firefox.nix
          ../../../hm/ashuramaruzxc/git.nix
          ../../../hm/ashuramaruzxc/nixcord.nix
          # ../../../hm/ashuramaruzxc/nushell.nix
          ../../../hm/ashuramaruzxc/ssh.nix
          ../../../hm/ashuramaruzxc/starship.nix
          ../../../hm/ashuramaruzxc/vscode.nix

          inputs.sops-nix.homeManagerModules.sops
          {
            sops = {
              age.keyFile = "${config.home.homeDirectory}/Library/Application\ Support/sops/age/keys.txt";
              defaultSopsFile = ../../../../secrets/unsigned-int8.yaml;
            };
          }

          ../../../../modules/hm
          {
            hm = {
              bash.enable = true;
              direnv.enable = true;
              fastfetch.enable = true;
              firefox = {
                enable = true;
                floorp.enable = true;
                defaultSearchEngine = "kagi";
              };
              fzf.enable = true;
              git.enable = true;
              helix.enable = true;
              mpv.enable = true;
              nixcord.enable = true;
              # nushell.enable = true;
              nvf.enable = true;
              vscode.enable = true;
              yazi.enable = true;
              zellij.enable = true;
            };
          }

          # Misc
          {
            home = {
              file."Documents/development/catppuccin/catppuccin-userstyles.json".source =
                (pkgs.callPackage ../../../../pkgs/catppuccin-userstyles.nix {
                  inherit (config.catppuccin) accent flavor;
                }).outPath
                + "/dist/import.json";
            };
          }

          {
            home.packages =
              builtins.attrValues {
                inherit (pkgs)
                  # Make macos useful
                  alt-tab-macos
                  hidden-bar
                  rectangle
                  raycast
                  iina # frontend for ffmpeg
                  iterm2 # default iterm but if it was better
                  ;

                # SNS
                inherit (pkgs)
                  signal-desktop-bin # just in case
                  materialgram
                  ;

                # Utilities
                inherit (pkgs)
                  # blender # 3D creation suite
                  # Graphics
                  #! qbittorrent @ashuramaruzxc: for some reason only works on nixos-unstable
                  #! kdenlive brew
                  #! krita brew
                  #! obs-studio brew
                  anki-bin # Japenis
                  audacity
                  gimp # Image editing
                  inkscape # Vector graphics
                  yubikey-manager # OTP
                  ;
                /**
                  * NOOOOOOO ❗❗❗ 🙀 😾 BUT LE PIRACY LE BAD HOW WILL SONY AND OTHER
                  * MULTIBILLION CORPORATIONS MAKE MONEY OF COPYRIGHTED SONGS WHAT ABOUT THE
                  * SHARE HOLDERS VALUE ❗❗❗ 🙀
                */
                inherit (pkgs) nicotine-plus;

                # Gaming
                inherit (pkgs)
                  winetricks
                  # Misc
                  #! xemu brew
                  # flycast
                  # prismlauncher
                  # Nintendo
                  #! mgba brew
                  # dolphin-emu
                  #! cemu
                  ryubing
                  # Playstation
                  chiaki # remote-play
                  duckstation-bin # PlayStation 1 emulator
                  #! ppsspp # PlayStation PSP emulator BREW
                  #! rpcs3
                  #! shadps4
                  ;
                inherit (pkgs.nixpkgs_x86_64-darwin)
                  # misc
                  #! np2kai
                  # Playstation
                  pcsx2-bin
                  ;
                inherit (pkgs.unstable-small) prismlauncher qbittorrent;
                inherit (pkgs.jetbrains) dataspell datagrip;
              }
              ++ (
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
                      "rust"
                      "go"
                    ]
                  );
                }
              );
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
      };
    extraSpecialArgs = { inherit inputs release; };
  };
}
