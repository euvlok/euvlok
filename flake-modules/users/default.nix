{ lib, ... }:
{
  imports = lib.trivial.pipe (lib.filesystem.readDir ./.) [
    (lib.attrsets.filterAttrs (
      name: type:
      type == "regular"
      && lib.strings.hasSuffix ".nix" name
      && !lib.lists.elem name [
        "default.nix"
        "flake.nix"
      ]
    ))
    (lib.attrsets.mapAttrsToList (name: _type: lib.path.append ./. name))
  ];
}
