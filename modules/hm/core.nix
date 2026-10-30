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

  # Home Manager's NixOS/nix-darwin integration injects the system package at
  # the same priority as Determinate's module sets null. Prefer the externally
  # managed Determinate installation explicitly.
  nix.package = lib.modules.mkForce null;
  manual.manpages.enable = lib.modules.mkDefault false;
}
