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
  imports = [ inputs.home-manager-ashuramaruzxc.darwinModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.ashuramaru =
      { osConfig, ... }:
      {
        imports = [
          { home.stateVersion = "24.11"; }
          inputs.catppuccin.homeModules.catppuccin
          { catppuccin = { inherit (osConfig.catppuccin) enable accent flavor; }; }

          ../../../hm/ashuramaruzxc/firefox.nix
          ../../../hm/ashuramaruzxc/nushell.nix

          ../../../../modules/hm
          {
            hm = {
              bash.enable = true;
              direnv.enable = true;
              fastfetch.enable = true;
              firefox.defaultSearchEngine = "Kagi";
              firefox.enable = true;
              fzf.enable = true;
              ghostty.enable = true;
              git.enable = true;
              helix.enable = true;
              mpv.enable = true;
              nixcord.enable = true;
              nushell.enable = true;
              ssh.enable = true;
              vscode.enable = true;
              # yazi.enable = true;
              zellij.enable = true;
            };
          }
        ];

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
              signal-desktop # just in case
              materialgram # Telegram but better
              dino # Jabber client gstreamer-vaapi is unsupported
              ;

            # Utilities
            inherit (pkgs)
              # Audio
              anki
              audacity
              qbittorrent
              nicotine-plus

              # Graphics
              #! krita brew
              gimp # Image editing
              inkscape # Vector graphics
              #! kdenlive brew
              #! obs-studio brew
              blender # 3D creation suite

              yubikey-manager # OTP

              ;

            # Gaming
            inherit (pkgs)
              winetricks
              # Misc
              #! xemu brew
              #! np2kai
              flycast
              prismlauncher

              # Nintendo
              #! mgba brew
              dolphin-emu
              #! cemu
              ryubing

              # Playstation
              chiaki # remote-play
              duckstation-bin # PlayStation 1 emulator
              #TODO pcsx2-bin # PlayStation 2 emulator maybe later
              #! ppsspp # PlayStation PSP emulator BREW
              #! rpcs3
              #! shadps4

              # Stores
              gogdl
              ;
            inherit (pkgs.jetbrains) dataspell datagrip;
          }
          // (
            let
              inherit (pkgs.unstable.jetbrains.plugins) addPlugins;
              inherit (pkgs.unstable.jetbrains) rider clion idea-ultimate;
              commonPlugins = [
                "better-direnv"
                "catppuccin-icons"
                "catppuccin-theme"
                "csv-editor"
                "ini"
                "nix-lsp"
                "nixidea"
                "rainbow-brackets"
              ];
            in
            {
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
      };
    extraSpecialArgs = { inherit inputs release; };
  };
}
