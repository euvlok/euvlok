{
  inputs,
  pkgs,
  config,
  osConfig,
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
  imports = [ inputs.home-manager-ashuramaruzxc.nixosModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.ashuramaru = {
      imports = [
        { home.stateVersion = "24.11"; }
        inputs.catppuccin.homeModules.catppuccin
        { inherit (osConfig) catppuccin; }
        ./systemd-utils.nix

        ../../../../modules/hm
        inputs.sops-nix.homeManagerModules.sops
        {
          sops = {
            age.keyFile = "/Users/marie/.config/sops/age/keys.txt";
            defaultSopsFile = ../../../../secrets/ashuramaruzxc_unsigned-int32.yaml;
          };
        }
        {
          hm = {
            bash.enable = true;
            chromium.enable = true;
            direnv.enable = true;
            fastfetch.enable = true;
            firefox.enable = true;
            fzf.enable = true;
            # git.enable = true;
            mpv.enable = true;
            nixcord.enable = true;
            nushell.enable = true;
            nvf.enable = true;
            ssh.enable = true;
            vscode.enable = true;
            zellij.enable = true;
            zsh.enable = true;
          };
        }

        {
          home.sessionVariables = {
            XCURSOR_THEME = "Remilia";
            XCURSOR_SIZE = 32;
          };

          services.easyeffects.enable = true;

          home.packages =
            builtins.attrValues {
              # Multimedia
              inherit (pkgs)
                nicotine-plus
                quodlibet-full
                vlc
                ;
              inherit (pkgs.kdePackages)
                k3b
                kamera
                ktorrent
                ;
              # Graphics & Design
              inherit (pkgs)
                blender # 3D creation suite
                gimp # Image editing
                godot3 # Game engine
                inkscape # Vector graphics
                krita # Digital painting
                obs-studio # Streaming and recording
                ;
              inherit (pkgs.kdePackages)
                kdenlive # Video editing
                ;
              # Productivity
              inherit (pkgs)
                anki # Flashcard app
                libreoffice-fresh
                obsidian
                tenacity # Audio recording/editing
                ;
              # Social & Communication
              inherit (pkgs)
                dino # Jabber client
                signal-desktop # Signal desktop client
                tdesktop # Telegram desktop
                ;
              # Utilities
              inherit (pkgs)
                ani-cli # Anime downloader
                cdrtools # cd burner CLI
                feather # monero
                helvum # Jack controls
                imgbrd-grabber
                media-downloader
                pavucontrol # PulseAudio volume control
                qpwgraph
                thefuck # Correcting previous command
                yt-dlp # youtube and whatnot media downloader
                ;

              # Gaming
              inherit (pkgs.unstable) osu-lazer-bin;
              inherit (pkgs)
                # Utils
                goverlay # Game overlay for Linux
                mangohud # Vulkan overlay

                # Misc
                bottles # Play On Linux but modern
                flycast # Sega Dreamcast emulator
                np2kai # PC-98 emulator
                prismlauncher # Minecraft launcher
                xemu # Xbox emulator

                # Nintendo
                cemu # Wii U emulator
                dolphin-emu # GameCube and Wii emulator
                mgba # Game Boy Advance emulator
                ryujinx # Nintendo Switch emulator

                # PlayStation
                chiaki # PS4 Remote Play
                duckstation # PlayStation 1 emulator
                pcsx2 # PlayStation 2 emulator
                ppsspp # PlayStation Portable emulator
                rpcs3 # PlayStation 3 emulator
                shadps4 # PlayStation 4 emulator

                # Stores
                gogdl # GOG Galaxy downloader
                heroic # Epic Games Store client
                ;

              # Development Tools
              inherit (pkgs) android-studio nixd;
              inherit (pkgs.jetbrains) dataspell datagrip;

              cinnamon = pkgs.nemo-with-extensions.override {
                extensions = builtins.attrValues {
                  inherit (pkgs)
                    folder-color-switcher
                    nemo-emblems
                    nemo-fileroller
                    nemo-python
                    nemo-qml-plugin-dbus
                    ;
                };
              };
            }
            ++ (
              let
                inherit (pkgs.unstable.jetbrains.plugins) addPlugins;
                inherit (pkgs.unstable.jetbrains) rider clion idea-ultimate;
                commonPlugins = [
                  "better-direnv"
                  "catppuccin-icons"
                  "catppuccin-theme"
                  "csv-editor"
                  "ini"
                  # "nix-lsp"
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
                pinentry = pkgs.pinentry-qt;
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
