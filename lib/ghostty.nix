inputs: self: super:
let
  mkSuper = superKey: k: c: "${superKey}+${k}=${c}";
  mkSuperPerf = superKey: k: c: "performable:${superKey}+${k}=${c}";
  mkSuperShift = superKey: k: c: "${superKey}+shift+${k}=${c}";
  mkSuperShiftNested = superKey: p: k: c: "${superKey}+shift+${p}>${k}=${c}";
in
{
  inherit
    mkSuper
    mkSuperPerf
    mkSuperShift
    mkSuperShiftNested
    ;
}
