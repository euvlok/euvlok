{
  inputs,
  lib,
  config,
  ...
}:
let
  inherit (config.nixpkgs.hostPlatform) isLinux;

  registry = lib.mapAttrs (_: flake: { inherit flake; }) (
    lib.filterAttrs (_: lib.isType "flake") inputs
  );
in
{
  config = (
    lib.mkMerge [
      (lib.mkIf isLinux {
        # Add inputs to legacy (nix2) channels, making legacy nix commands consistent
        environment.etc = lib.optionalAttrs isLinux (
          lib.mapAttrs' (name: value: {
            name = "nix/path/${name}";
            value.source = value.flake;
          }) config.nix.registry
        );
      })
      (lib.mkIf isLinux { nix.registry = lib.mkForce registry; })
      {
        nix = {
          settings = {
            experimental-features = "nix-command flakes";

            substituters = [
              "https://devenv.cachix.org"
              "https://hyprland.cachix.org"
              "https://nix-community.cachix.org"
              "https://nixos-raspberrypi.cachix.org"
            ];
            trusted-public-keys = [
              "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
              "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
              "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
              "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
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

          # Flake Inputs
          nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") (
            lib.filterAttrs (_: lib.isType "flake") inputs
          );
        };
      }
    ]
  );
}
