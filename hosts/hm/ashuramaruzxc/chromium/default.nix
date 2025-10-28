{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.mkIf pkgs.stdenvNoCC.isLinux {
    hm.chromium = {
      enable = true;
      browser = "chromium";
      extraExtensions = (pkgs.callPackage ./extensions.nix { inherit config; });
    };
  };
}
