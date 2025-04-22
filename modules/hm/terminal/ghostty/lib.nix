{ superKey }:
{
  mkSuper = k: c: "${superKey}+${k}=${c}";
  mkSuperPerf = k: c: "performable:${superKey}+${k}=${c}";
  mkSuperShift = k: c: "${superKey}+shift+${k}=${c}";
  mkSuperShiftNested =
    p: k: c:
    "${superKey}+shift+${p}>${k}=${c}";
}
