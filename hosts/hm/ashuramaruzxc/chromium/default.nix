{
  pkgs,
  lib,
  config,
  ...
}:
{
  programs.chromium.extensions = lib.flatten [
    (pkgs.callPackage ./extensions.nix { inherit config; })
  ];
}
