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
  };

  home.activation.raycastProfile = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    export RAYCAST_APP_BUNDLE=${lib.strings.escapeShellArg "${raycastPackage}/Applications/Raycast.app"}
    run ${lib.meta.getExe raycastManager} key extract > /dev/null
    apps=$(${lib.meta.getExe raycastManager} db call appIndex.getAllByContentType '[0]')
    aliases=$(printf '%s\n' "$apps" | ${lib.meta.getExe pkgs.jq} -c \
      --argjson wanted ${lib.strings.escapeShellArg (builtins.toJSON wantedAppAliases)} \
      '[ $wanted[] as $want
         | (.result | map(select(.name as $name | $want.names | index($name))) | .[0]) as $app
         | ($app.raycastId // $want.fallbackPath) as $path
         | select($path != null)
         | { id: ("c:r:applications::*::application::=::" + $path),
             extensionId: "e:r:applications", alias: $want.alias, enabled: true }
       ] + [ { id: "c:r:clipboard-history::-::history",
               extensionId: "e:r:clipboard-history", alias: "clip", enabled: true } ]')
    profile=$(${lib.meta.getExe raycastManager} db profile get | ${lib.meta.getExe pkgs.jq} -c \
      --arg id ${lib.strings.escapeShellArg avatarId} \
      --arg name ${lib.strings.escapeShellArg fallbackName} \
      '.currentUser // { id: $id, name: $name } | .has_pro_features = true')
    config_file=$(${lib.meta.getExe' pkgs.coreutils "mktemp"})
    trap '${lib.meta.getExe' pkgs.coreutils "rm"} -f "$config_file"' EXIT
    ${lib.meta.getExe pkgs.jq} -n \
      --argjson currentUser "$profile" \
      --argjson commandAliases "$aliases" \
      --arg avatarUrl 'https://avatars.githubusercontent.com/u/${avatarId}?v=4' \
      '{ profile: { currentUser: $currentUser, avatarUrl: $avatarUrl },
         commandAliases: $commandAliases, disableAi: true }' \
      > "$config_file"
    run ${lib.meta.getExe raycastManager} configure "$config_file"
  '';
}
