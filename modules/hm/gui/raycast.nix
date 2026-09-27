{
  avatarId,
  fallbackName,
  raycastModule,
  raycastPackage,
}:
{
  config,
  ...
}:
let
  homeApps = "${config.home.homeDirectory}/${config.targets.darwin.copyApps.directory}";
  wantedAppAliases = [
    {
      names = [ "ChatGPT" ];
      alias = "codex";
      fallbackPath = "${homeApps}/ChatGPT.app";
    }
    {
      names = [
        "Zen Browser (Twilight)"
        "Zen Browser"
        "Zen"
      ];
      alias = "firefox";
      fallbackPath = "${homeApps}/Zen Browser (Twilight).app";
    }
    {
      names = [ "Helium" ];
      alias = "chrome";
      fallbackPath = "${homeApps}/Helium.app";
    }
    {
      names = [ "Ghostty" ];
      alias = "terminal";
    }
    {
      names = [ "IINA" ];
      alias = "video";
    }
    {
      names = [
        "qbittorrent"
        "qBittorrent"
      ];
      alias = "torrent";
    }
    {
      names = [ "Shottr" ];
      alias = "screenshot";
    }
  ];
in
{
  imports = [ raycastModule ];

  programs.raycast = {
    enable = true;
    package = raycastPackage;
    configuration.settings = {
      profile = {
        fallbackUser = {
          id = avatarId;
          name = fallbackName;
        };
        currentUserPatch = {
          has_pro_features = true;
          organizations = [ ];
        };
        avatarUrl = "https://avatars.githubusercontent.com/u/${avatarId}?v=4";
      };
      appAliases = wantedAppAliases;
      clipboardHistoryDuration = "unlimited";
      commandAliases = [
        {
          id = "c:r:clipboard-history::-::history";
          extensionId = "e:r:clipboard-history";
          alias = "clip";
          enabled = true;
        }
      ];
      disableAi = true;
    };
  };
}
