{ lib, pkgs, ... }:
{
  packages = lib.attrsets.attrValues { inherit (pkgs.unstable) sbcl; };
  zed.extensions = [
    "scheme"
    "elisp"
  ];
}
