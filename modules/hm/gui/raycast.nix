{
  avatarId,
  fallbackName,
  raycastManager,
  raycastModule,
  raycastPackage,
}:
{
  config,
  lib,
  pkgs,
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

  home.activation.raycastClipboard = lib.hm.dag.entryAfter [ "raycast" ] ''
    clipboard=$(${lib.meta.getExe raycastManager} db call settings.getInternalExtensionSettings '["e:r:clipboard-history"]')
    clipboard_update=$(printf '%s\n' "$clipboard" | ${lib.meta.getExe pkgs.jq} -ce \
      'select(.result != null) | ["e:r:clipboard-history", { syncedMeta: ((.result.syncedMeta // {}) + { historyDuration: "unlimited" }) }]')
    ${lib.meta.getExe raycastManager} db call settings.updateInternalExtensionSettings "$clipboard_update" > /dev/null
    ${lib.meta.getExe raycastManager} db call settings.getInternalExtensionSettings '["e:r:clipboard-history"]' \
      | ${lib.meta.getExe pkgs.jq} -e '.result.syncedMeta.historyDuration == "unlimited"' > /dev/null
  '';
}
