{ pkgs, config, ... }:
{
  hm.chromium = {
    enable = true;
    browser = "chromium";
    extraExtensions = (pkgs.callPackage ./extensions.nix { inherit config; });
  };
}
