{ euvlokInputs, isDarwin }:
{ lib, ... }:
{
  imports = [
    (lib.modules.importApply ./nix { inherit euvlokInputs isDarwin; })
    (lib.modules.importApply ./nixpkgs.nix { inherit euvlokInputs; })
    ./packages.nix
  ];
}
