{
  pkgs,
  lib,
  config,
  ...
}:
let
  extensions = lib.flatten [ (pkgs.callPackage ./extensions.nix { inherit config; }) ];
in
{
  hm.chromium.brave.extraExtensions = extensions;
  hm.chromium.chromium.extraExtensions = extensions;
  hm.chromium.vivaldi.extraExtensions = extensions;
}
