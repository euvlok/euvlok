{ lib, pkgs, ... }:
{
  imports = [
    (lib.modules.importApply ../../../../modules/darwin/fonts.nix {
      packages = lib.attrsets.attrValues {
        inherit (pkgs.nerd-fonts)
          jetbrains-mono
          monaspace
          noto
          hack
          ;
      };
    })
  ];
}
