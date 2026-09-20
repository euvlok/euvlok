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

  home-manager.users.hushh =
    { lib, ... }:
    {
      imports = [
        {
          home.stateVersion = "25.05";
          home.sessionVariables = {
            DEFAULT_BROWSER = "${zenBrowserPackage}/bin/zen";
            SHELL = "fish";
            TERM = "alacritty";
          };
        }
      ]
      ++ [
        {
          programs.mangohud.enable = true;
          programs.mangohud.settings = {
            fps_limit = 200;
            no_display = true;
          };
          fonts.fontconfig.enable = true;
          home.pointerCursor.enable = true;
          xsession.numlock.enable = true;
        }
      ]
      ++ [
        ./home-packages.nix
        {
          home.shell.enableShellIntegration = true;
          programs.codex.settings = lib.modules.mkForce { };
          euvlok.home = {
            codex.enable = true;
            fastfetch.enable = true;
            firefox.zen-browser.enable = true;
            bash.enable = true;
            fish.enable = true;
            helix.enable = true;
            hyprland.enable = true;
            mpv.enable = true;
            zed-editor.enable = true;
            #vscode.enable = true; # This is a massive pain in the ass if you change your vscode config json frequently. Just going to manage it normally instead of declaratively.
            nixcord.enable = true;
          };
        }
      ]
      ++ [
        spicetify.homeManagerModules.default
        {
          programs.spicetify.enable = true;
          programs.spicetify.enabledExtensions = builtins.attrValues {
            inherit (spicetify.legacyPackages.${pkgs.stdenvNoCC.hostPlatform.system}.extensions)
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
}
