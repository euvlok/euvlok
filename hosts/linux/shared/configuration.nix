{ lib, config, ... }:
{
  # Add inputs to legacy (nix2) channels, making legacy nix commands consistent
  environment.etc = lib.optionalAttrs config.nixpkgs.hostPlatform.isLinux (
    lib.mapAttrs' (name: value: {
      name = "nix/path/${name}";
      value.source = value.flake;
    }) config.nix.registry
  );
}
