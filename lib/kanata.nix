inputs: self: super:
let
  inherit (super)
    concatMapStringsSep
    concatStringsSep
    isInt
    isList
    mapAttrsToList
    optional
    pipe
    trim
    ;

  formatSchemeList = keysList: "(${concatStringsSep " " keysList})";

  formatKeyList = concatStringsSep " ";

  mkVariable =
    name: value:
    let
      valueStr =
        if isInt value then
          toString value
        else if isList value then
          formatSchemeList value
        else
          value;
    in
    "(defvar ${name} ${valueStr})";

  mkAlias = name: definition: "${name} ${definition}";

  mkTapHold =
    aliasName: tapKey: holdAction: timeoutHold: timeoutTap:
    mkAlias aliasName "(tap-hold ${toString timeoutHold} ${toString timeoutTap} ${tapKey} ${holdAction})";

  mkTapHoldReleaseKeys =
    aliasName: tapKey: holdAction: timeoutHold: timeoutTap: releaseKeysList:
    mkAlias aliasName "(tap-hold-release-keys ${toString timeoutHold} ${toString timeoutTap} ${tapKey} ${holdAction} ${formatSchemeList releaseKeysList})";

  mkLayerSwitch =
    aliasName: tapKey: layerName: timeoutHold: timeoutTap:
    mkTapHold aliasName tapKey "(layer-switch ${layerName})" timeoutHold timeoutTap;

  mkLayerWhileHeld =
    aliasName: tapKey: layerName: timeoutHold: timeoutTap:
    mkTapHold aliasName tapKey "(layer-while-held ${layerName})" timeoutHold timeoutTap;

  mkMultiMod =
    aliasName: tapKey: modifiers: timeoutHold: timeoutTap:
    mkTapHold aliasName tapKey "(multi ${concatStringsSep " " modifiers})" timeoutHold timeoutTap;

  mkLayer = name: keyMappings: ''
    (deflayer ${name}
      ${formatKeyList keyMappings}
    )
  '';

  mkChord =
    keys: action: timeoutVar: behavior: disabledLayers:
    "${formatSchemeList keys} ${action} ${timeoutVar} ${behavior} ${formatSchemeList disabledLayers}";

  mapKeys = keyList: mappingFn: super.map mappingFn keyList;

  mapKey =
    key: mapping:
    if builtins.isString mapping then
      mapping
    else if builtins.isAttrs mapping then
      if mapping ? alias then
        "@${mapping.alias}"
      else if mapping ? key then
        mapping.key
      else
        key
    else
      key;

  mkLocalKeys = localKeyDefs: ''
    (deflocalkeys-linux
      ${concatStringsSep "\n  " (
        mapAttrsToList (name: keycode: "${name} ${toString keycode}") localKeyDefs
      )}
    )
  '';

  mkConfig =
    {
      variables ? { },
      aliases ? [ ],
      layers ? { },
      chords ? [ ],
      sourceKeys,
      localKeys ? { },
      extraDefCfg ? [ ],
    }:
    let
      varsSection = super.mapAttrsToList mkVariable variables;
      localKeysSection = if localKeys == { } then "" else mkLocalKeys localKeys;
      aliasesSection =
        if aliases == [ ] then
          ""
        else
          ''
            (defalias
              ${concatMapStringsSep "\n  " trim aliases}
            )
          '';
      layersSection = mapAttrsToList mkLayer layers;
      chordsSection =
        if chords == [ ] then
          ""
        else
          ''
            (defchordsv2
              ${concatStringsSep "\n  " chords}
            )
          '';
    in
    concatStringsSep "\n" (
      builtins.concatLists [
        [ ";; Generated Kanata config by Nix" ]
        (optional (localKeysSection != "") localKeysSection)
        [
          ''
            (defsrc
              ${formatKeyList sourceKeys}
            )
          ''
        ]
        varsSection
        (optional (chordsSection != "") chordsSection)
        layersSection
        (optional (aliasesSection != "") aliasesSection)
      ]
    );

  mkHomeRowModConfig =
    {
      keys,
      mods,
      behavior ? "tap-hold",
      tapTimeout ? 220,
      holdTimeout ? 240,
      releaseKeys ? [ ],
    }:
    let
      keyModPairs = super.zipLists keys mods;
    in
    super.foldl' super.recursiveUpdate { } (
      super.map (
        { fst, snd }:
        {
          ${fst} = {
            mod = snd;
            inherit
              behavior
              tapTimeout
              holdTimeout
              releaseKeys
              ;
          };
        }
      ) keyModPairs
    );

  mkNavigationLayer =
    {
      name ? "nav",
      keys ? [
        "left"
        "down"
        "up"
        "right"
      ],
      positions ? [
        7
        8
        9
        10
      ], # hjkl positions in common layouts
      fillWith ? "_",
    }:
    let
      totalKeys = 16; # Common layout size
      navMap = super.listToAttrs (
        super.zipListsWith (pos: key: {
          name = toString pos;
          value = key;
        }) positions keys
      );
    in
    {
      ${name} = super.genList (i: navMap.${toString i} or fillWith) totalKeys;
    };
in
{
  inherit
    formatKeyList
    formatSchemeList
    mapKey
    mapKeys
    mkAlias
    mkChord
    mkConfig
    mkHomeRowModConfig
    mkLayer
    mkLayerSwitch
    mkLayerWhileHeld
    mkLocalKeys
    mkMultiMod
    mkNavigationLayer
    mkTapHold
    mkTapHoldReleaseKeys
    mkVariable
    ;
}
