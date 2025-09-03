{
  lib,
  eulib,
  ...
}:
let
  superKey = "super";
  inherit (eulib)
    mkSuper
    mkSuperShift
    mkSuperShiftNested
    ;

  directions = {
    up = "top";
    down = "bottom";
    left = "left";
    right = "right";
  };

  splits =
    let
      mkSplitCommands = k: v: [
        (mkSuperShiftNested superKey "s" k "new_split:${k}")
        (mkSuperShiftNested superKey "r" k "resize_split:${k},30")
        (mkSuperShift superKey k "goto_split:${v}")
      ];
    in
    lib.flatten (lib.mapAttrsToList mkSplitCommands directions)
    ++ [
      (mkSuper superKey "t" "new_tab")
      (mkSuper superKey "e" "equalize_splits")
    ];
in
{
  programs.ghostty.settings.keybind = splits;
}
