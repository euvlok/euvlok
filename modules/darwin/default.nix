{ euvlokInputs }:
{ lib, ... }:
{
  imports = [
    euvlokInputs.determinate.darwinModules.default
    (lib.modules.importApply ../cross {
      inherit euvlokInputs;
      isDarwin = true;
    })
    ./nix.nix
    (lib.modules.importApply ./sops.nix { inherit euvlokInputs; })
    ./system.nix
  ];
}
