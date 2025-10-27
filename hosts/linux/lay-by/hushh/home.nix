{
  inputs,
  pkgs,
  eulib,
  pkgsUnstable,
  ...
}:
{
  imports = [ inputs.home-manager-lay-by.nixosModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs eulib pkgsUnstable; };
  };

  home-manager.users.hushh =
    { osConfig, ... }:
    {
      imports = [
        {
          home.stateVersion = "25.05";
          home.sessionVariables = {
            DEFAULT_BROWSER = "${inputs.zen-browser-trivial.packages.x86_64-linux.default}/bin/zen";
            SHELL = "fish";
            TERM = "alacritty";
          };
        }
      ]
      ++ [
        inputs.stylix-trivial.homeModules.stylix
      ]
      ++ [
        {
          programs.mangohud.enable = true;
          programs.mangohud.settings = {
            fps_limit = 200;
            no_display = true;
          };
          programs.rofi.enable = true;
          programs.rofi.package = inputs.nixpkgs-lay-by.legacyPackages.x86_64-linux.rofi-wayland;
          services.easyeffects.enable = true;
          fonts.fontconfig.enable = true;
          xsession.numlock.enable = true;
        }
      ]
      ++ [
        ./home-packages.nix
        inputs.self.homeModules.default
        inputs.self.homeConfigurations.lay-by
        {
          home.shell.enableShellIntegration = true;
          hm = {
            fastfetch.enable = true;
            firefox.zen-browser.enable = true;
            bash.enable = true;
            fish.enable = true;
            helix.enable = true;
            hyprland.enable = true;
            mpv.enable = true;
            vscode.enable = true;
            nixcord.enable = true;
          };
        }
      ]
      ++ [
        inputs.spicetify-nix-trivial.homeManagerModules.default
        {
          programs.spicetify.enable = true;
          programs.spicetify.enabledExtensions = builtins.attrValues {
            inherit (inputs.spicetify-nix-trivial.legacyPackages.${pkgs.system}.extensions)
              adblock
              beautifulLyrics # Apple Music like Lyrics
              copyLyrics
              fullAlbumDate
              popupLyrics # Popup window with the current song's lyrics scrolling across it
              shuffle # Shuffle properly, using Fisher-Yates with zero bias
              ;
          };
        }
      ]
      ++ [
        inputs.catppuccin-trivial.homeModules.catppuccin
        { catppuccin = { inherit (osConfig.catppuccin) enable accent flavor; }; }
      ];
    };
}
