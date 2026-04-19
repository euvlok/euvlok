specialArgs: self: super:
let
  entries = builtins.readDir ./.;
  isOverlayFile =
    name:
    entries.${name} == "regular" && name != "default.nix" && builtins.match ".*\\.nix" name != null;
  overlayFiles = builtins.filter isOverlayFile (builtins.attrNames entries);
in
builtins.foldl' (
  acc: name: acc // (import (./. + "/${name}") specialArgs self super)
) { } overlayFiles
