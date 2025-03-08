{
  pkgs,
  lib,
  config,
  ...
}:
let
  funcs = pkgs.callPackage ./lib.nix { };

  inherit (funcs)
    formatKeyList
    formatSchemeList
    generateTapHold
    generateTapHoldReleaseKeys
    ;

  inherit (lib)
    concatMapStringsSep
    concatStringsSep
    mapAttrsToList
    mkEnableOption
    mkOption
    optional
    optionals
    optionalString
    splitString
    ;

  inherit (lib.types)
    attrsOf
    bool
    either
    enum
    int
    listOf
    nullOr
    str
    submodule
    ;

  generateKanataConfig = (
    kcfg:
    let
      vars = mapAttrsToList (name: value: ''
        (defvar ${name} ${
          if lib.isInt value then
            toString value
          else if lib.isList value then
            formatSchemeList value # Assume list of strings for now
          else
            value # Assume raw string for complex things
        })
      '') kcfg.variables;

      hrmAliases = optionals kcfg.homeRowMods.enable (
        mapAttrsToList (
          key: keyCfg:
          let
            actualAliasName = if keyCfg.aliasName != null then keyCfg.aliasName else key;
            actualTapBehavior =
              if keyCfg.tapBehavior != null then keyCfg.tapBehavior else kcfg.homeRowMods.defaultTapBehavior;
            actualTimeoutTap =
              if keyCfg.timeoutTap != null then keyCfg.timeoutTap else kcfg.variables."tap-timeout";
            actualTimeoutHold =
              if keyCfg.timeoutHold != null then keyCfg.timeoutHold else kcfg.variables."hold-timeout";

            actualReleaseKeysValue =
              if actualTapBehavior == "tap-hold-release-keys" then
                if keyCfg.releaseKeysVar == null then
                  throw "homeRowMods.keys.${key}: 'releaseKeysVar' must be set because the effective 'tapBehavior' is 'tap-hold-release-keys'."
                else if !lib.hasPrefix "$" keyCfg.releaseKeysVar then
                  throw "homeRowMods.keys.${key}: 'releaseKeysVar' (\"${keyCfg.releaseKeysVar}\") must start with '$' to reference a variable from kcfg.variables."
                else
                  let
                    varName = lib.removePrefix "$" keyCfg.releaseKeysVar;
                  in
                  if builtins.hasAttr varName kcfg.variables then
                    kcfg.variables.${varName}
                  else
                    throw "homeRowMods.keys.${key}: Variable '\$${varName}' referenced by 'releaseKeysVar' not found in kcfg.variables."
              else
                null;
          in
          if actualTapBehavior == "tap-hold" then
            generateTapHold actualAliasName key keyCfg.mod actualTimeoutHold actualTimeoutTap
          else if actualTapBehavior == "tap-hold-release-keys" then
            generateTapHoldReleaseKeys actualAliasName key keyCfg.mod actualTimeoutHold actualTimeoutTap
              actualReleaseKeysValue
          else
            throw "Internal logic error: Invalid actualTapBehavior '${builtins.toJSON actualTapBehavior}' evaluated for key ${key}. Expected 'tap-hold' or 'tap-hold-release-keys'."
        ) kcfg.homeRowMods.keys
      );

      layerNavAlias = optionals kcfg.layerNav.enable [
        (generateTapHold "layer-nav" kcfg.layerNav.key "(layer-while-held nav-layer)"
          kcfg.variables.hold-timeout
          kcfg.variables.tap-timeout
        )
      ];

      hrmToggleAliases = optionals (kcfg.homeRowMods.enable && kcfg.homeRowMods.layerToggle.enable) [
        ''${kcfg.homeRowMods.layerToggle.modsOnAlias} (tap-hold ${toString kcfg.variables.tap-timeout} ${toString kcfg.variables.toggle-hold-time} ${kcfg.homeRowMods.layerToggle.key} (layer-switch base-no-mods))''
        ''${kcfg.homeRowMods.layerToggle.modsOffAlias} (tap-hold ${toString kcfg.variables.tap-timeout} ${toString kcfg.variables.toggle-hold-time} ${kcfg.homeRowMods.layerToggle.key} (layer-switch base))''
      ];

      hyperkeyAlias = optionals kcfg.hyperkey.enable [
        (
          if kcfg.hyperkey.tapBehavior == "tap-hold" then
            generateTapHold kcfg.hyperkey.aliasName kcfg.hyperkey.tapKey "(multi lctl lalt lsft lmet)"
              (
                if kcfg.hyperkey.timeoutHold != null then
                  kcfg.hyperkey.timeoutHold
                else
                  kcfg.variables."hold-timeout"
              )
              (
                if kcfg.hyperkey.timeoutTap != null then kcfg.hyperkey.timeoutTap else kcfg.variables."tap-timeout"
              )
          else if kcfg.hyperkey.tapBehavior == "tap-hold-release-keys" then
            (
              if kcfg.hyperkey.releaseKeysVar == null then
                throw "hyperkey: 'releaseKeysVar' must be set because 'tapBehavior' is 'tap-hold-release-keys'."
              else
                generateTapHoldReleaseKeys kcfg.hyperkey.aliasName kcfg.hyperkey.tapKey
                  "(multi lctl lalt lsft lmet)"
                  (
                    if kcfg.hyperkey.timeoutHold != null then
                      kcfg.hyperkey.timeoutHold
                    else
                      kcfg.variables."hold-timeout"
                  )
                  (
                    if kcfg.hyperkey.timeoutTap != null then kcfg.hyperkey.timeoutTap else kcfg.variables."tap-timeout"
                  )
                  kcfg.hyperkey.releaseKeysVar
            )
          else
            throw "Invalid hyperkey.tapBehavior: ${kcfg.hyperkey.tapBehavior}"
        )
      ];

      customAliases = mapAttrsToList (name: value: "${name} ${value}") kcfg.aliases;

      allAliases = hrmAliases ++ layerNavAlias ++ hrmToggleAliases ++ hyperkeyAlias ++ customAliases;

      baseLayerKeys = lib.map (
        key:
        if kcfg.hyperkey.enable && key == kcfg.hyperkey.key then
          "@${kcfg.hyperkey.aliasName}"
        else if kcfg.capsLockEscapeSwap.enable && key == "caps" then
          "esc"
        else if kcfg.homeRowMods.enable && builtins.hasAttr key kcfg.homeRowMods.keys then
          let
            rawAlias = kcfg.homeRowMods.keys.${key}.aliasName;
            alias = if rawAlias == null then key else rawAlias;
          in
          "@${alias}"
        else if
          kcfg.homeRowMods.enable
          && kcfg.homeRowMods.layerToggle.enable
          && key == kcfg.homeRowMods.layerToggle.key
        then
          "@${kcfg.homeRowMods.layerToggle.modsOnAlias}"
        else if kcfg.layerNav.enable && key == kcfg.layerNav.key then
          "@layer-nav"
        else
          key
      ) kcfg.sourceKeys;

      baseNoModsLayerKeys = optionals (kcfg.homeRowMods.enable && kcfg.homeRowMods.layerToggle.enable) (
        map (
          key:
          if kcfg.hyperkey.enable && key == kcfg.hyperkey.key then
            "@${kcfg.hyperkey.aliasName}"
          else if kcfg.capsLockEscapeSwap.enable && key == "caps" then
            "esc"
          # No HRM aliases like @a, @s etc.
          else if kcfg.homeRowMods.layerToggle.enable && key == kcfg.homeRowMods.layerToggle.key then
            "@${kcfg.homeRowMods.layerToggle.modsOffAlias}"
          else if kcfg.layerNav.enable && key == kcfg.layerNav.key then
            "@layer-nav"
          else
            key
        ) kcfg.sourceKeys
      );

      navLayerKeys = optionals kcfg.layerNav.enable lib.map (
        key: kcfg.layerNav.layerMapping.${key} or "_"
      ) kcfg.sourceKeys;

      layers =
        [
          ''
            (deflayer base
              ${formatKeyList baseLayerKeys}
            )
          ''
        ]
        ++ optional (kcfg.homeRowMods.enable && kcfg.homeRowMods.layerToggle.enable) ''
          (deflayer base-no-mods
            ${formatKeyList baseNoModsLayerKeys}
          )
        ''
        ++ optional kcfg.layerNav.enable ''
          (deflayer nav-layer
            ${formatKeyList navLayerKeys}
          )
        ''
        ++ mapAttrsToList (name: keys: ''
          (deflayer ${name}
            ${formatKeyList keys}
          )
        '') kcfg.customLayers;

      chords = optionals (kcfg.chords.enable) (
        lib.map (
          chord:
          let
            keysStr = formatSchemeList chord.keys;
            # Conditionally add "base-no-mods" to the disabled layers list based on updated config path
            finalDisabledLayers =
              if kcfg.homeRowMods.layerToggle.enable && kcfg.homeRowMods.layerToggle.toggleChordsAlso then
                chord.disabledLayers ++ [ "base-no-mods" ]
              else
                chord.disabledLayers;
            disabledLayersStr = formatSchemeList finalDisabledLayers;
            inherit (chord) action timeoutVar behavior;
          in
          "${keysStr} ${action} ${timeoutVar} ${behavior} ${disabledLayersStr}"
        ) kcfg.chords.definitions
      );
    in
    concatStringsSep "\n" [
      ";; Generated Kanata config by Nix"
      ''
        (defsrc
          ${formatKeyList kcfg.sourceKeys}
        )
      ''
      (concatStringsSep "\n" vars)
      (optionalString kcfg.chords.enable ''
        (defchordsv2
          ${concatStringsSep "\n  " chords}
        )
      '')
      (concatStringsSep "\n\n" layers)
      (optionalString (allAliases != [ ]) ''
        (defalias
          ${concatMapStringsSep "\n  " (aliasStr: lib.trim aliasStr) allAliases}
        )
      '')
    ]
  );
in
{
  options.nixos.kanata = {
    enable = mkEnableOption "Kanata Key Remapper Service";

    config = {
      sourceKeys = mkOption {
        default = splitString " " "esc caps a s d f e h j k l ; o spc bksl";
        type = listOf str;
      };

      variables = mkOption {
        default = { }; # Top-level default is empty, defaults are handled inside the submodule options
        description = "Variables used within the Kanata configuration.";
        type = submodule {
          freeformType = either int (either str (listOf str));
          options = {
            tap-timeout = mkOption {
              default = 220;
              type = int;
              description = "Default timeout (ms) for tap actions in tap-hold.";
            };
            hold-timeout = mkOption {
              default = 240;
              type = int;
              description = "Default timeout (ms) to trigger hold actions in tap-hold.";
            };
            combo-timeout = mkOption {
              default = 50;
              type = int;
              description = "Default timeout (ms) for chords (bilateral combinations).";
            };
            toggle-hold-time = mkOption {
              default = 500;
              type = int;
              description = "Hold time (ms) required for the HRM layer toggle key.";
            };
            left-hand-keys = mkOption {
              default = lib.splitString " " "q w e r t a s d f g z x c v b";
              type = listOf str;
            };
            right-hand-keys = mkOption {
              default = lib.splitString " " "y u i o p h j k l ; n m , . /";
              type = listOf str;
            };
          };
        };
        example = {
          tap-timeout = 180;
          my-custom-timeout = 150;
          some-keys = lib.splitString " " "a b c";
        };
      };

      capsLockEscapeSwap = {
        enable = mkOption {
          default = true;
          type = bool;
        };
      };

      hyperkey = {
        enable = mkEnableOption "Hyperkey (Ctrl+Alt+Shift+Meta combination)";
        key = mkOption {
          default = "bksl";
          type = str;
        };

        aliasName = mkOption {
          default = "hyper";
          type = str;
        };

        tapBehavior = mkOption {
          default = "tap-hold";
          type = enum (splitString " " "tap-hold tap-hold-release-keys");
        };

        tapKey = mkOption {
          default = "bksl";
          type = str;
        };

        timeoutTap = mkOption {
          default = null;
          type = nullOr int;
        };

        timeoutHold = mkOption {
          default = null;
          type = nullOr int;
        };

        releaseKeysVar = mkOption {
          default = null;
          type = nullOr str;
        };
      };

      homeRowMods = {
        enable = mkEnableOption "Home Row Modifier Keys";
        defaultTapBehavior = mkOption {
          default = "tap-hold";
          type = enum (splitString " " "tap-hold tap-hold-release-keys");
        };

        keys = mkOption {
          type = attrsOf (submodule {
            options = {
              mod = mkOption {
                example = "lctl";
                type = str;
              };
              aliasName = mkOption {
                default = null;
                type = nullOr str;
              };
              tapBehavior = mkOption {
                default = null;
                type = nullOr (enum (splitString " " "tap-hold tap-hold-release-keys"));
              };
              releaseKeysVar = mkOption {
                default = null;
                type = nullOr str;
              };
              timeoutTap = mkOption {
                default = null;
                type = nullOr int;
              };
              timeoutHold = mkOption {
                default = null;
                type = nullOr int;
              };
            };
          });
          default = {
            a = {
              mod = "lmet";
              tapBehavior = "tap-hold-release-keys";
              releaseKeysVar = "$left-hand-keys";
            };
            s = {
              mod = "lalt";
              tapBehavior = "tap-hold-release-keys";
              releaseKeysVar = "$left-hand-keys";
            };
            d = {
              mod = "lctl";
              tapBehavior = "tap-hold-release-keys";
              releaseKeysVar = "$left-hand-keys";
            };
            f = {
              mod = "lsft";
              tapBehavior = "tap-hold-release-keys";
              releaseKeysVar = "$left-hand-keys";
            };

            j.mod = "rsft";
            j.aliasName = "kmod1";
            k.mod = "rctl";
            k.aliasName = "kmod2";
            l.mod = "ralt";
            l.aliasName = "kmod3";
            ";".mod = "rmet";
            ";".aliasName = "scol";
          };
        };

        layerToggle = {
          enable = mkOption {
            type = bool;
            default = true;
          };
          key = mkOption {
            default = "o";
            type = str;
          };
          modsOnAlias = mkOption {
            default = "hrm-toggle-on";
            type = str;
          };
          modsOffAlias = mkOption {
            default = "hrm-toggle-off";
            type = str;
          };
          toggleChordsAlso = mkOption {
            default = true;
            type = bool;
          };
        };
      };

      layerNav = {
        enable = mkEnableOption "Navigation Layer on Key Hold (Default: Spacebar)";
        key = mkOption {
          default = "spc";
          type = str;
        };
        layerMapping = mkOption {
          default = {
            h = "left";
            j = "down";
            k = "up";
            l = "right";
            # Other keys default to "_" (transparent)
          };
          type = attrsOf str;
        };
      };

      chords = {
        enable = mkEnableOption "Bilateral Combinations (Chords)";
        definitions = mkOption {
          default = [
            {
              keys = splitString " " "a s";
              action = "bspc";
            }
            {
              keys = splitString " " "s d";
              action = "del";
            }
            {
              keys = splitString " " "k l";
              action = "ret";
            }
            {
              keys = splitString " " "j k";
              action = "tab";
            }
          ];
          type = listOf (submodule {
            options = {
              keys = mkOption {
                example = splitString " " "a s";
                type = listOf str;
              };
              action = mkOption {
                example = "bspc";
                type = str;
              };
              timeoutVar = mkOption {
                default = "$combo-timeout";
                type = str;
              };
              behavior = mkOption {
                default = "first-release";
                type = str;
              };
              disabledLayers = mkOption {
                default = [ ];
                type = listOf str;
              };
            };
          });
        };
      };

      aliases = mkOption {
        default = { };
        type = attrsOf str;
        example.esc = "caps";
      };

      customLayers = mkOption {
        default = { };
        type = attrsOf (listOf str);
        example.numpad = splitString " " "_ _ kp7 kp8 kp9 _ _ _ kp4 kp5 kp6 kp/ _ kp0";
      };
    };
  };

  config =
    let
      inherit (config.nixos.kanata.config)
        hyperkey
        homeRowMods
        layerNav
        chords
        variables
        ;
      inherit (homeRowMods) layerToggle;
    in
    lib.mkIf config.nixos.kanata.enable {
      assertions =
        (optional (hyperkey.enable && homeRowMods.enable && layerToggle.enable) {
          assertion = hyperkey.key != layerToggle.key;
          message = "Kanata Configuration Error: The Hyperkey key ('${hyperkey.key}') cannot be the same as the HRM Layer Toggle key ('${layerToggle.key}').";
        })
        ++ (optional (hyperkey.enable && layerNav.enable) {
          assertion = hyperkey.key != layerNav.key;
          message = "Kanata Configuration Error: The Hyperkey key ('${hyperkey.key}') cannot be the same as the Layer Navigation activation key ('${layerNav.key}').";
        })
        ++ (optional (homeRowMods.enable && layerToggle.enable && layerNav.enable) {
          assertion = layerToggle.key != layerNav.key;
          message = "Kanata Configuration Error: The HRM Layer Toggle key ('${layerToggle.key}') cannot be the same as the Layer Navigation activation key ('${layerNav.key}').";
        });

      services.kanata = {
        enable = true;
        package = pkgs.kanata-with-cmd;
        keyboards.main = {
          config = generateKanataConfig config.nixos.kanata.config;
          extraDefCfg = concatStringsSep " " (
            [
              "danger-enable-cmd yes"
              "process-unmapped-keys yes"
            ]
            ++ optional (chords.enable
              or (homeRowMods.enable && homeRowMods.defaultTapBehavior == "tap-hold-release-keys")
            ) "concurrent-tap-hold yes"
            ++ optional chords.enable "chords-v2-min-idle ${toString variables.combo-timeout}"
          );
        };
      };
    };
}
