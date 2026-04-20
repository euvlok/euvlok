specialArgs: self: super:
let
  entries = builtins.readDir ./.;
  # Plain-data files (imported directly where needed, not curried as eulib overlays).
  dataFiles = [ "catppuccin.nix" ];
  isOverlayFile =
    name:
    entries.${name} == "regular"
    && name != "default.nix"
    && !(builtins.elem name dataFiles)
    && builtins.match ".*\\.nix" name != null;
  overlayFiles = builtins.filter isOverlayFile (builtins.attrNames entries);
in
builtins.foldl' (
  acc: name: acc // (import (./. + "/${name}") specialArgs self super)
) { } overlayFiles
