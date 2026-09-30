{
  homeManagerModule,
  personalModule,
  sharedModule,
  spicetify,
  zenBrowserPackage,
}:
{
  pkgs,
  ...
}:
{
  imports = [ homeManagerModule ];

  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    sharedModules = [
      sharedModule
      personalModule
    ];
  };

  home-manager.users.hushh = {
    imports = [
      {
        home.stateVersion = "26.05";
        home.sessionVariables = {
          DEFAULT_BROWSER = "${zenBrowserPackage}/bin/zen";
          SHELL = "fish";
          TERM = "alacritty";
        };
        fonts.fontconfig.enable = true;
        home.pointerCursor.enable = true;
      }
      ./home-packages.nix
      (import ../../../../slop.nix).homeManager.codex
      {
        home.shell.enableShellIntegration = true;
        programs.fastfetch.enable = true;
        programs.bash.enable = true;
        programs.fish.enable = true;
        programs.mpv.enable = true;
        euvlok.home = {
          firefox.zen-browser.enable = true;
          helix.enable = true;
          hyprland.enable = true;
          nixcord.enable = true;
        };
      }
      spicetify.homeManagerModules.default
      {
        programs.spicetify.enable = true;
        programs.spicetify.enabledExtensions = builtins.attrValues {
          inherit (spicetify.legacyPackages.${pkgs.stdenvNoCC.hostPlatform.system}.extensions)
            adblock
            beautifulLyrics
            copyLyrics
            fullAlbumDate
            popupLyrics
            shuffle
            ;
        };
      }
    ];
  };
}
