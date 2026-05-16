{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.modules.mkIf pkgs.stdenvNoCC.isLinux {
    hm.chromium = {
      enable = true;
      browser = lib.modules.mkDefault "helium-browser";
      extraExtensions = (pkgs.callPackage ./extensions.nix { inherit config; });
    };
  };
}
