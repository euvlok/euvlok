{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (config.nixpkgs.hostPlatform) isLinux isDarwin;

  registry = lib.mapAttrs (_: flake: { inherit flake; }) (
    lib.filterAttrs (_: lib.isType "flake") inputs
  );
in
{
  imports = [ inputs.lix-module-source.nixosModules.default ];

  options.cross.nix.enable = lib.mkEnableOption "Nix";
  options.nixos.lix.enable = lib.mkEnableOption "Lix" // {
    default = true;
  };

  config = lib.mkIf config.cross.nix.enable (
    lib.mkMerge [
      (lib.mkIf isLinux {
        # Add inputs to legacy (nix2) channels, making legacy nix commands consistent
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
      (lib.mkIf (!isDarwin) { nix.registry = lib.mkForce registry; })
      {
        nix = {
          settings = {
            experimental-features =
              "nix-command flakes "
              + lib.optionalString (config.nix.package.pname == "lix") "pipe-operator"
              + lib.optionalString (config.nix.package.pname == "nix") "pipe-operators";

            substituters = [
              "https://devenv.cachix.org"
              "https://helix.cachix.org"
              "https://hyprland.cachix.org"
              "https://nix-community.cachix.org"
              "https://nixos-raspberrypi.cachix.org"
              "https://yazi.cachix.org"
            ];
            trusted-public-keys = [
              "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
              "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
              "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
              "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
              "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
              "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
            ];
          }
          // lib.optionalAttrs isLinux {
            # Disable global registry
            flake-registry = "";
            # Workaround for https://github.com/NixOS/nix/issues/9574
            nix-path = config.nix.nixPath;
          };
          # Obviously, we don't want channels; they're imperatively managed. Disabling
          # them means that the `nixpkgs` instance with which the host was built is used
          # as the "de facto" channel when referring to `<nixpkgs>`
          channel.enable = false;

          nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") (
            # Flake Inputs
            lib.filterAttrs (_: lib.isType "flake") inputs
          );
        };
      }
      (lib.mkIf config.nixos.lix.enable {
        nixpkgs.overlays = [
          (final: prev: {
            inherit (prev.lixPackageSets.latest)
              nixpkgs-review
              nix-direnv
              nix-eval-jobs
              nix-fast-build
              colmena
              ;
          })
        ];
        nix.package = pkgs.lixPackageSets.latest.lix;
      })
    ]
  );
}
