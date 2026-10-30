{ euvlokInputs }:
{
  config,
  lib,
  osConfig ? null,
  ...
}:
let
  # Prefer this module's platforms, then the parent system's when integrated
  hostPlatform = config.nixpkgs.hostPlatform.system or (osConfig.nixpkgs.hostPlatform.system or null);
  buildPlatform =
    config.nixpkgs.buildPlatform.system or (osConfig.nixpkgs.buildPlatform.system or hostPlatform);
in
{
  options.euvlok.nixpkgs.unstableSource = lib.options.mkOption {
    type = lib.types.path;
    default = euvlokInputs.nixpkgs-unstable-small;
    description = "Top-level Nixpkgs store path imported as pkgs.unstable.";
  };

  config = {
    nixpkgs.config.allowUnfree = true;
    nixpkgs.overlays = [
      (import ../../overlay.nix {
        inherit hostPlatform buildPlatform;
        inputs = euvlokInputs;
        unstableSource = config.euvlok.nixpkgs.unstableSource;
      })
    ];
  };
}
