{
  avatarId,
  fallbackName,
  raycastManager,
  raycastModule,
  raycastPackage,
}:
{ lib, pkgs, ... }:
{
  imports = [ raycastModule ];

  programs.raycast = {
    enable = true;
    package = raycastPackage;
  };

  home.activation.raycastProfile = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    export RAYCAST_APP_BUNDLE=${lib.strings.escapeShellArg "${raycastPackage}/Applications/Raycast.app"}
    run ${lib.meta.getExe raycastManager} key extract > /dev/null
    profile=$(${lib.meta.getExe raycastManager} db profile get | ${lib.meta.getExe pkgs.jq} -c \
      --arg id ${lib.strings.escapeShellArg avatarId} \
      --arg name ${lib.strings.escapeShellArg fallbackName} \
      '.currentUser // { id: $id, name: $name } | .has_pro_features = true')
    config_file=$(${lib.meta.getExe' pkgs.coreutils "mktemp"})
    trap '${lib.meta.getExe' pkgs.coreutils "rm"} -f "$config_file"' EXIT
    ${lib.meta.getExe pkgs.jq} -n \
      --argjson currentUser "$profile" \
      --arg avatarUrl 'https://avatars.githubusercontent.com/u/${avatarId}?v=4' \
      '{ profile: { currentUser: $currentUser, avatarUrl: $avatarUrl }, disableAi: true }' \
      > "$config_file"
    run ${lib.meta.getExe raycastManager} configure "$config_file"
  '';
}
