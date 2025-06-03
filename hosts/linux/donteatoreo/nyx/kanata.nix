{ pkgs, ... }:
let
  kanataLib = pkgs.callPackage ../../../../modules/nixos/kanata/lib.nix { };
  inherit (kanataLib)
    mkHomeRowModConfig
    mkLayerSwitch
    mkLayerWhileHeld
    mkNavigationLayer
    ;

  leftHandKeys = [
    "q"
    "w"
    "e"
    "r"
    "t"
    "a"
    "s"
    "d"
    "f"
    "g"
    "z"
    "x"
    "c"
    "v"
    "b"
  ];

  rightHandKeys = [
    "y"
    "u"
    "i"
    "o"
    "p"
    "h"
    "j"
    "k"
    "l"
    ";"
    "n"
    "m"
    ","
    "."
    "/"
  ];

  homeRowMods =
    mkHomeRowModConfig {
      keys = [
        "a"
        "s"
        "d"
        "f"
      ];
      mods = [
        "lmet"
        "lalt"
        "lctl"
        "lsft"
      ];
      behavior = "tap-hold-release-keys";
      releaseKeys = leftHandKeys;
    }
    // mkHomeRowModConfig {
      keys = [
        "j"
        "k"
        "l"
        ";"
      ];
      mods = [
        "rsft"
        "rctl"
        "ralt"
        "rmet"
      ];
      behavior = "tap-hold";
    };

  navLayer = mkNavigationLayer {
    name = "arrow-layer";
    positions = [
      7
      8
      9
      10
    ]; # hjkl positions
  };
in
{
  nixos.kanata = {
    enable = true;
    config = {
      # Custom keycodes and source keys
      localKeys = {
        my_side_button = 275; # BTN_SIDE -> VolDown
        my_extra_button = 276; # BTN_EXTRA -> VolUp
      };

      sourceKeys = [
        "esc"
        "caps"
        "a"
        "s"
        "d"
        "f"
        "e"
        "h"
        "j"
        "k"
        "l"
        ";"
        "o"
        "spc"
        "my_side_button"
        "my_extra_button"
      ];

      variables = {
        tap-timeout = 220;
        hold-timeout = 240;
        toggle-hold-time = 500;
        left-hand-keys = leftHandKeys;
        right-hand-keys = rightHandKeys;
      };

      aliases = [
        # Space navigation
        (mkLayerWhileHeld "spc-nav" "spc" "arrow-layer" 240 220)

        # Toggle modifiers on/off with 'o' key
        (mkLayerSwitch "o-mods-on" "o" "base-no-mods" 500 220)
        (mkLayerSwitch "o-mods-off" "o" "base" 500 220)
      ];

      layers = {
        base = [
          "caps"
          "esc"
          "@a"
          "@s"
          "@d"
          "@f"
          "e"
          "h"
          "@j"
          "@k"
          "@l"
          "@;"
          "@o-mods-on"
          "@spc-nav"
          "vold"
          "volu"
        ];

        base-no-mods = [
          "caps"
          "esc"
          "a"
          "s"
          "d"
          "f"
          "e"
          "h"
          "j"
          "k"
          "l"
          ";"
          "@o-mods-off"
          "@spc-nav"
          "vold"
          "volu"
        ];
      } // navLayer;

      helpers.mkHomeRowMods = homeRowMods;

      extraDefCfg = [
        "danger-enable-cmd yes"
        "process-unmapped-keys yes"
        "concurrent-tap-hold yes"
      ];
    };
  };
}
