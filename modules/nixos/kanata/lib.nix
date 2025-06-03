{ lib }:
let
  inherit (lib)
    concatMapStringsSep
    concatStringsSep
    isInt
    isList
    mapAttrsToList
    optional
    pipe
    trim
    ;

  formatSchemeList =
    keysList:
    pipe keysList [
      (concatStringsSep " ")
      (s: "(${s})")
    ];

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

  # Layer switching functions using function composition
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
    pipe
      [ keys action timeoutVar behavior disabledLayers ]
      [
        (
          parts:
          "${formatSchemeList (builtins.head parts)} ${builtins.elemAt parts 1} ${builtins.elemAt parts 2} ${builtins.elemAt parts 3} ${formatSchemeList (builtins.elemAt parts 4)}"
        )
      ];

  mapKeys = keyList: mappingFn: lib.map mappingFn keyList;

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

  mkLocalKeys =
    localKeyDefs:
    pipe localKeyDefs [
      (mapAttrsToList (name: keycode: "${name} ${toString keycode}"))
      (concatStringsSep "\n  ")
      (content: ''
        (deflocalkeys-linux
          ${content}
        )
      '')
    ];

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
      varsSection = lib.mapAttrsToList mkVariable variables;
      localKeysSection = if localKeys == { } then "" else mkLocalKeys localKeys;
      aliasesSection = pipe aliases [
        (aliases: if aliases == [ ] then "" else aliases)
        (
          aliases:
          if aliases == "" then
            ""
          else
            ''
              (defalias
                ${concatMapStringsSep "\n  " trim aliases}
              )
            ''
        )
      ];
      layersSection = pipe layers [
        (mapAttrsToList mkLayer)
      ];
      chordsSection = pipe chords [
        (
          chords:
          if chords == [ ] then
            ""
          else
            ''
              (defchordsv2
                ${concatStringsSep "\n  " chords}
              )
            ''
        )
      ];
      configSections =
        pipe
          [
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
          [
            (builtins.concatLists)
            (concatStringsSep "\n")
          ];
    in
    configSections;

  # Create a home row mod configuration helper
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
      keyModPairs = lib.zipLists keys mods;
    in
    pipe keyModPairs [
      (lib.map (
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
      ))
      (lib.foldl' lib.recursiveUpdate { })
    ];

  # Helper for common layer patterns
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
      navMap = lib.listToAttrs (
        lib.zipListsWith (pos: key: {
          name = toString pos;
          value = key;
        }) positions keys
      );
    in
    {
      ${name} = lib.genList (i: navMap.${toString i} or fillWith) totalKeys;
    };
in
{
  inherit
    formatKeyList
    formatSchemeList

    # Variables
    mkVariable

    # Aliases
    mkAlias
    mkTapHold
    mkTapHoldReleaseKeys
    mkLayerSwitch
    mkLayerWhileHeld
    mkMultiMod

    # Local keys
    mkLocalKeys

    # Layers
    mkLayer

    # Chords
    mkChord

    # Key mapping
    mapKeys
    mapKey

    # Config assembly
    mkConfig

    # Enhanced helpers
    mkHomeRowModConfig
    mkNavigationLayer
    ;
}
