inputs: self: super:
let
  resetLicense =
    drv:
    drv.overrideAttrs (prev: {
      meta = (prev.meta or { }) // {
        license = [ ];
      };
    });
in
{
  mkExt =
    { system }:
    publisher: extension:
    resetLicense
      inputs.nix-vscode-extensions-trivial.extensions.${system}.vscode-marketplace.${publisher}.${extension};

  # Override entire extension sets to reset all licenses
  vscode-marketplace =
    { system }:
    super.lib.mapAttrsRecursive (
      _: resetLicense
    ) inputs.nix-vscode-extensions-trivial.extensions.${system}.vscode-marketplace;

  vscode-marketplace-release =
    { system }:
    super.lib.mapAttrsRecursive (
      _: resetLicense
    ) inputs.nix-vscode-extensions-trivial.extensions.${system}.vscode-marketplace-release;

  open-vsx =
    { system }:
    super.lib.mapAttrsRecursive (
      _: resetLicense
    ) inputs.nix-vscode-extensions-trivial.extensions.open-vsx;

  open-vsx-release =
    { system }:
    super.lib.mapAttrsRecursive (
      _: resetLicense
    ) inputs.nix-vscode-extensions-trivial.extensions.open-vsx-release;
}
