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
      browser = lib.mkDefault "helium-browser";
      extraExtensions = (pkgs.callPackage ./extensions.nix { inherit config; });
    };
  };
}
