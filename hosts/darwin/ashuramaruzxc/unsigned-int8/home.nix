{
  inputs,
  pkgs,
  config,
  ...
}:
let
  release =
    if builtins.hasAttr "darwinRelease" config.system then
      builtins.fromJSON (config.system.darwinRelease)
    else
      builtins.fromJSON (config.system.nixos.release);
in
{
  imports = [ inputs.home-manager-donteatoreo.darwinModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.ashuramaru = {
      imports = [
        { home.stateVersion = "24.11"; }
        inputs.catppuccin.homeModules.catppuccin
        {
          catppuccin = {
            enable = true;
            flavor = "mocha";
            accent = "rosewater";
          };
        }

        ../../../hm/ashuramaruzxc/firefox.nix
        ../../../hm/ashuramaruzxc/nushell.nix
        ../../../hm/ashuramaruzxc/starship.nix
        ../../../hm/ashuramaruzxc/vscode.nix
        ../../../../modules/hm
        {
          hm = {
            bash.enable = true;
            direnv.enable = true;
            fastfetch.enable = true;
            firefox.defaultSearchEngine = "Kagi";
            firefox.enable = true;
            fzf.enable = true;
            git.enable = true;
            helix.enable = true;
            mpv.enable = true;
            nixcord.enable = true;
            nushell.enable = true;
            nvf.enable = true;
            ssh.enable = true;
            vscode.enable = true;
            yazi.enable = true;
            zellij.enable = true;
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
                # signal-desktop # just in case
                # dino # Jabber client gstreamer-vaapi is unsupported
                ;

              # Utilities
              inherit (pkgs)
                # blender # 3D creation suite
                # Graphics
                #! qbittorrent
                #! kdenlive brew
                #! krita brew
                #! obs-studio brew
                anki-bin # Japenis
                audacity
                gimp # Image editing
                inkscape # Vector graphics
                nicotine-plus # Errrrm but le piracy le bad
                yubikey-manager # OTP
                ;

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
                #! TODO # PlayStation 2 emulator maybe later
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
              inherit (pkgs.unstable-small) prismlauncher;
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
