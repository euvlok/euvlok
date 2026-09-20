{ euvlokInputs }:
{
  config,
  lib,
  osConfig ? null,
  ...
}:
let
  hostPlatform = lib.attrsets.attrByPath [ "nixpkgs" "hostPlatform" "system" ] (
    if osConfig == null then null else osConfig.nixpkgs.hostPlatform.system
  ) config;
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
        inherit hostPlatform;
        inputs = euvlokInputs;
        unstableSource = config.euvlok.nixpkgs.unstableSource;
      })
    ];
  };
}
