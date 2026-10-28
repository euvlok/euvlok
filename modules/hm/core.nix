{
  euvlokInputs,
  includeNixpkgs,
}:
{ lib, ... }:
{
  imports = [
    # Do not put nixpkgs' upstream Nix ahead of Determinate Nix on PATH.
    euvlokInputs.determinate.homeManagerModules.default
  ]
  ++ lib.lists.optional includeNixpkgs (
    lib.modules.importApply ./nixpkgs.nix { inherit euvlokInputs; }
  );

  # NixOS injects a system package at the same priority as Determinate's null
  # default, while ndw owns its Determinate runtime directly. Neither should
  # install another Nix package through Home Manager
  nix.package = lib.modules.mkForce null;
  manual.manpages.enable = lib.modules.mkDefault false;
}
