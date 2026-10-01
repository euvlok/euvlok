{ euvlokInputs }:
{
  config,
  lib,
  osConfig ? null,
  ...
}:
let
  hostPlatform = lib.attrsets.attrByPath [
    "nixpkgs"
    "hostPlatform"
    "system"
  ] (osConfig.nixpkgs.hostPlatform.system or null) config;
  buildPlatform = lib.attrsets.attrByPath [
    "nixpkgs"
    "buildPlatform"
    "system"
  ] (osConfig.nixpkgs.buildPlatform.system or hostPlatform) config;
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
