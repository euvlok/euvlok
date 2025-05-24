{
  inputs,
  config,
  pkgs,
  ...
}:
let
  release = builtins.fromJSON (config.system.nixos.release);
in
{
  imports = [ inputs.home-manager-ashuramaruzxc.nixosModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "bak";
    users.root =
      { osConfig, ... }:
      {
        imports = [
          { home.stateVersion = "25.05"; }
          inputs.catppuccin-trivial.homeModules.catppuccin
          { catppuccin = { inherit (osConfig.catppuccin) enable accent flavor; }; }
          ../../../hm/ashuramaruzxc/starship.nix
          ../shared/aliases.nix

          ../../../../modules/hm
          {
            hm = {
              bash.enable = true;
              direnv.enable = true;
              fzf.enable = true;
              helix.enable = true;
              nh.enable = true;
              nvf.enable = true;
              zellij.enable = true;
              zsh.enable = true;
            };
          }
        ];
      };
    users.ashuramaru =
      { osConfig, ... }:
      {
        imports = [
          { home.stateVersion = "25.05"; }
          inputs.catppuccin-trivial.homeModules.catppuccin
          { catppuccin = { inherit (osConfig.catppuccin) enable accent flavor; }; }

          ../shared/aliases.nix
          ../../../hm/ashuramaruzxc/aliases.nix
          ../../../hm/ashuramaruzxc/chrome.nix
          ../../../hm/ashuramaruzxc/dconf.nix
          # ../../../hm/ashuramaruzxc/firefox.nix
          ../../../hm/ashuramaruzxc/flatpak.nix
          ../../../hm/ashuramaruzxc/git.nix
          ../../../hm/ashuramaruzxc/graphics.nix
          ../../../hm/ashuramaruzxc/nixcord.nix
          ../../../hm/ashuramaruzxc/nushell.nix
          ../../../hm/ashuramaruzxc/ssh.nix
          ../../../hm/ashuramaruzxc/starship.nix
          ../../../hm/ashuramaruzxc/vscode.nix
          inputs.sops-nix-trivial.homeManagerModules.sops
          {
            sops = {
              age.keyFile = "$HOME/.config/sops/age/keys.txt";
              defaultSopsFile = ../../../../secrets/ashuramaruzxc_unsigned-int32.yaml;
            };
          }

          ../../../../modules/hm
          {
            hm = {
              bash.enable = true;
              chromium.enable = true;
              direnv.enable = true;
              fastfetch.enable = true;
              firefox = {
                enable = true;
                floorp.enable = true;
                zen-browser.enable = true;
                defaultSearchEngine = "kagi";
              };
              fzf.enable = true;
              ghostty.enable = true;
              git.enable = true;
              helix.enable = true;
              mpv.enable = true;
              nh.enable = true;
              nixcord.enable = true;
              nushell.enable = true;
              nvf.enable = true;
              ssh.enable = true;
              vscode.enable = true;
              yazi.enable = true;
              zellij.enable = true;
              zsh.enable = true;
            };
          }
          ../../../linux/shared/protonmail-bridge.nix
          {
            services.protonmail-bridge.enable = true;
          }

          {
            home.packages =
              builtins.attrValues {
                # Important
                inherit (pkgs)
                  keepassxc
                  bitwarden
                  thunderbird
                  ;
                # Multimedia
                inherit (pkgs)
                  nicotine-plus
                  qbittorrent
                  quodlibet-full
                  tenacity # Audio recording/editing
                  vlc
                  youtube-music
                  ;
                inherit (pkgs.kdePackages)
                  k3b
                  kamera
                  ktorrent
                  ;
                # Productivity
                inherit (pkgs)
                  anki # Flashcard app
                  francis
                  gImageReader
                  libreoffice-qt6-fresh
                  obsidian
                  octaveFull
                  pdftk
                  treesheets
                  ;
                # Social & Communication
                inherit (pkgs)
                  dino # Jabber client
                  element-desktop # matrix client
                  materialgram # tg client but better
                  nextcloud-client # nextcloud client
                  protonmail-bridge-gui
                  signal-desktop # Signal desktop client
                  zoom-us
                  ;
                # Networking
                inherit (pkgs)
                  mullvad-vpn
                  nekoray
                  openvpn
                  protonvpn-cli
                  protonvpn-gui
                  udptunnel
                  v2raya
                  ;
                inherit (pkgs)
                  feather # monero
                  helvum # Jack controls
                  pavucontrol # PulseAudio volume control
                  qpwgraph
                  ;

                # Gaming
                inherit (pkgs.unstable) osu-lazer-bin;
                inherit (pkgs)
                  # Utils
                  goverlay # Game overlay for Linux
                  mangohud # Vulkan overlay

                  # Misc
                  flycast # Sega Dreamcast emulator
                  # np2kai # PC-98 emulator
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
                  # rpcs3 # PlayStation 3 emulator
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
                    # "nix-lsp"
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
      };
    extraSpecialArgs = { inherit inputs release; };
  };
}
