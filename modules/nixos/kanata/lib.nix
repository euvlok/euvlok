{ lib }:
let
  formatSchemeList = keysList: "(${lib.concatStringsSep " " keysList})";

  formatKeyList = keysList: lib.concatStringsSep " " keysList;

  generateTapHold = aliasName: tapKey: holdAction: timeoutHold: timeoutTap: ''
    ${aliasName} (tap-hold ${toString timeoutHold} ${toString timeoutTap} ${tapKey} ${holdAction})
  '';

  generateTapHoldReleaseKeys =
    aliasName: tapKey: holdAction: timeoutHold: timeoutTap: releaseKeysList: ''
      ${aliasName} (tap-hold-release-keys ${toString timeoutHold} ${toString timeoutTap} ${tapKey} ${holdAction} ${formatSchemeList releaseKeysList})
    '';
in
{
  inherit
    formatKeyList
    formatSchemeList
    generateTapHold
    generateTapHoldReleaseKeys
    ;
}
