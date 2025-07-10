_: _: super:
let
  inherit (super) mkMerge mapAttrsToList;
  mkBind = { modKey }: key: action: { "bind \"${modKey} ${key}\"" = action; };
  mkShiftBind = { modKey }: key: action: { "bind \"${modKey} Shift ${key}\"" = action; };
  # (no modifier key)
  mkSimpleBind = key: action: { "bind \"${key}\"" = action; };

  # Direction mappings
  directions = {
    Up = "Up";
    Down = "Down";
    Left = "Left";
    Right = "Right";
  };
in
{
  # Export directions for use in other modules
  inherit directions;

  # Export binding helper functions
  inherit mkBind mkShiftBind mkSimpleBind;

  mkDirectionalNav =
    modKey:
    mkMerge (mapAttrsToList (k: v: (mkShiftBind { inherit modKey; } k { MoveFocus = v; })) directions);

  mkDirectionalNewPane = mkMerge (
    mapAttrsToList (
      k: v:
      mkSimpleBind k {
        NewPane = v;
        SwitchToMode = "Normal";
      }
    ) directions
  );

  mkDirectionalResize = mkMerge (
    mapAttrsToList (
      k: v:
      mkSimpleBind k {
        Resize = "Increase ${v}";
        SwitchToMode = "Normal";
      }
    ) directions
  );

  mkModeSwitch =
    modKey: key: mode:
    (mkBind { inherit modKey; } key { SwitchToMode = mode; });
  mkQuit = modKey: key: (mkBind { inherit modKey; } key { Quit = { }; });
}
