{
  inputs,
  lib,
  config,
  ...
}:
let
  inherit (config.nixpkgs.hostPlatform) isLinux;
in
{
  options.cross.nix.enable = lib.mkEnableOption "Nix";
  config = lib.mkIf config.cross.nix.enable (
    lib.mkMerge [
      (lib.mkIf config.nixpkgs.hostPlatform.isLinux {
        # # Add inputs to legacy (nix2) channels, making legacy nix commands consistent
        environment.etc = lib.optionalAttrs isLinux (
          lib.mapAttrs' (name: value: {
            name = "nix/path/${name}";
            value.source = value.flake;
          }) config.nix.registry
        );
        /*
          "truetype:interpreter-version=40" tells freetype to use version 40 of the
          TrueType bytecode interpreter
          "cff:no-stem-darkening=0" tells freetype to not darken the stems (the main
          vertical strokes) when processing fonts using the CFF engine
          "autofitter:no-stem-darkening=0" does the same for the autofitter component
          Essentially, it's a way to keep fonts looking as natural as they were
          designed, without any extra darkening that might make them look a tad heavier
        */
        environment.variables.FREETYPE_PROPERTIES = lib.optionalString isLinux "truetype:interpreter-version=40 cff:no-stem-darkening=0 autofitter:no-stem-darkening=0";
      })
      {
        nix = {
          settings =
            {
              experimental-features = "nix-command flakes pipe-operators";
              substituters = [
                "https://devenv.cachix.org"
                "https://nix-community.cachix.org"
              ];
              trusted-public-keys = [
                "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
                "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
              ];
            }
            // lib.optionalAttrs isLinux {
              # Disable global registry
              flake-registry = "";
            };
          # Obviously, we don't want channels; they're imperatively managed. Disabling
          # them means that the `nixpkgs` instance with which the host was built is used
          # as the "de facto" channel when referring to `<nixpkgs>`
          channel.enable = false;
          # Make flake registry and nix path match flake inputs
          # Using mkForce to override any existing registry definitions
          registry = lib.mkForce (
            lib.mapAttrs (_: flake: { inherit flake; }) (
              # Flake Inputs
              lib.filterAttrs (_: lib.isType "flake") inputs
            )
          );
          nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") (
            # Flake Inputs
            lib.filterAttrs (_: lib.isType "flake") inputs
          );
        };
      }
    ]
  );
}
