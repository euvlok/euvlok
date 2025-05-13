{
  inputs,
  config,
  ...
}:
let
  release = builtins.fromJSON (config.system.nixos.release);
in
{
  imports = [ inputs.home-manager-lay-by.nixosModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.hushh =
      { osConfig, ... }:
      {
        imports = [
          { home.stateVersion = "24.11"; }
          inputs.catppuccin-trivial.homeModules.catppuccin
          { catppuccin = { inherit (osConfig.catppuccin) enable accent flavor; }; }

          ../../../hm/lay-by/hyprland/dunst.nix
          ../../../hm/lay-by/hyprland/hypridle.nix
          ../../../hm/lay-by/hyprland/hyprland.nix
          ../../../hm/lay-by/hyprland/hyprlock.nix
          ../../../hm/lay-by/hyprland/waybar.nix
          {
            programs.rofi.enable = true;
            programs.rofi.package = inputs.nixpkgs-lay-by.legacyPackages.x86_64-linux.rofi-wayland;
          }

          inputs.stylix-trivial.homeManagerModules.stylix
          ../../../hm/lay-by/stylix.nix

          {
            home.sessionVariables = {
              DEFAULT_BROWSER = "${inputs.zen-browser-trivial.packages.x86_64-linux.default}/bin/zen";
            };
          }

          ../../../hm/lay-by/git.nix

          ../../../../modules/hm
          {
            home.shell.enableShellIntegration = true;
            hm = {
              bash.enable = true;
              chromium.enable = true;
              direnv.enable = true;
              fastfetch.enable = true;
              firefox.enable = true;
              firefox.zen-browser.enable = true;
              fish.enable = true;
              fzf.enable = true;
              ghostty.altKeyBehavior = true;
              ghostty.enable = true;
              git.enable = true;
              helix.enable = true;
              hyprland.enable = true;
              mpv.enable = true;
              nixcord.enable = true;
              ssh.enable = true;
              vscode.enable = true;
              yazi.enable = true;
              zsh.enable = true;
            };
          }

          {
            programs.mangohud = {
              enable = true;
              settings = {
                fps_limit = 200;
                no_display = true;
              };
            };
            services.easyeffects.enable = true;
            fonts.fontconfig.enable = true;
            xsession.numlock.enable = true;
          }

          inputs.spicetify-nix-trivial.homeManagerModules.default
          {
            programs.spicetify.enable = true;
            programs.spicetify.enabledExtensions = builtins.attrValues {
              inherit (inputs.spicetify-nix-trivial.legacyPackages.x86_64-linux.extensions)
                # NO❗❗❗ 🙀 😾 HOW WILL SPOTIFY MAKE MONEY FROM THEIR
                # AI-GENERATED SONGS AND KEEP ALL THE PROFITS FOR THEMSELVES?!
                # *(Allegedly)*
                adblock
                beautifulLyrics # Apple Music like Lyrics
                copyLyrics
                fullAlbumDate
                popupLyrics # Popup window with the current song's lyrics scrolling across it
                shuffle # Shuffle properly, using Fisher-Yates with zero bias
                ;
            };
          }
        ];
      };
    extraSpecialArgs = { inherit inputs release; };
  };
}
