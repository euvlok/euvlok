{ pkgs, lib, ... }:
let
  libFuncs = pkgs.callPackage ../../../modules/hm/terminal/ghostty/lib.nix { superKey = "super"; };
  inherit (libFuncs)
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
        (mkSuperShiftNested "s" k "new_split:${k}")
        (mkSuperShiftNested "r" k "resize_split:${k},30")
        (mkSuperShift k "goto_split:${v}")
      ];
    in
    lib.flatten (lib.mapAttrsToList mkSplitCommands directions)
    ++ [
      (mkSuper "t" "new_tab")
      (mkSuper "e" "equalize_splits")
    ];
in
{
  programs.ghostty.settings.keybind = splits;
}
