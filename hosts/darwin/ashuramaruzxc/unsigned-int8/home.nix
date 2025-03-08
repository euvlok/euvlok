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
    users.ashuramaru = {
      imports = [
        { home.stateVersion = "24.11"; }
        inputs.catppuccin.homeModules.catppuccin

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

      home.packages = builtins.attrValues {
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
          kotatogram-desktop # Telegram but better
          #TODO dino # Jabber client gstreamer-vaapi is unsupported
          ;

        # Utilities
        inherit (pkgs)
          # Audio
          anki-bin
          audacity
          nicotine-plus
          qbittorrent

          # Graphics
          #! krita brew
          gimp # Image editing
          inkscape # Vector graphics
          #! kdenlive brew
          #! obs-studio brew
          #! blender # 3D creation suite BREW

          yubikey-manager # OTP
          yt-dlp # must have
          ani-cli # Anime downloader
          thefuck # just for lulz
          ;

        # Gaming
        inherit (pkgs)
          # Misc
          #! xemu brew
          #! flycast brew
          prismlauncher

          # Nintendo
          #! mgba brew
          dolphin-emu

          # Playstation
          chiaki # remote-play
          duckstation-bin # PlayStation 1 emulator
          #TODO pcsx2-bin # PlayStation 2 emulator maybe later
          #! ppsspp # PlayStation PSP emulator BREW

          # Stores
          #! heroic brew
          gogdl
          ;

        inherit (pkgs) mono powershell;
        inherit (pkgs) sass deno;
        inherit (pkgs.jetbrains) rider clion;
        dotnetCorePackages = pkgs.dotnetCorePackages.combinePackages (
          builtins.attrValues {
            inherit (pkgs.dotnetCorePackages) sdk_8_0 sdk_9_0;
          }
        );
        nodejs = pkgs.nodejs.override {
          enableNpm = true;
          python3 = pkgs.python312;
        };
      };
    };
    extraSpecialArgs = { inherit inputs release; };
  };
}
