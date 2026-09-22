{
  euvlokInputs,
  includeNixpkgs,
}:
{ lib, ... }:
{
  imports = [
    (lib.modules.importApply ./core.nix {
      inherit euvlokInputs includeNixpkgs;
    })
    (lib.modules.importApply ./os { inherit euvlokInputs; })
  ]
  ++ [
    (lib.modules.importApply ./catppuccin { inherit euvlokInputs; })
    (lib.modules.importApply ./sops.nix { inherit euvlokInputs; })
    ./cli
    (lib.modules.importApply ./gui { inherit euvlokInputs; })
    ./languages
    ./shell
    ./terminal
    ./tui
    ./wm
  ];
}
