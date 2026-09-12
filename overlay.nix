{
  inputs,
  hostPlatform ? null,
  stableSource ? inputs.nixpkgs-stable,
  unstableSource ? inputs.nixpkgs-unstable-small,
}:
let
  # Keep the package-set layers independently readable even though consumers
  # normally install the composed overlay exported as `overlays.default`
  unstableOverlay = _final: prev: {
    unstable = import unstableSource {
      config = prev.config or { };
      localSystem = if hostPlatform == null then prev.stdenv.hostPlatform else hostPlatform;
    };
  };

  stableOverlay = _final: prev: {
    stable = import stableSource {
      localSystem = if hostPlatform == null then prev.stdenv.hostPlatform else hostPlatform;
    };
  };

  eupkgsOverlay = final: _prev: {
    eupkgs = final.unstable.extend inputs.eupkgs.overlays.default;
  };

  localPackagesOverlay = final: _prev: {
    euvlokVscodeExtensions =
      { version, extensions }:
      import (inputs.nix4vscode + /nix/forVscodeVersionRaw.nix) {
        inherit extensions version;
        pkgs = final.unstable;
      };
    linux-rt-upscaler = final.callPackage ./packages/linux-rt-upscaler.nix { };
    lsfg-vk = final.callPackage ./packages/lsfg-vk.nix { };
    nvidia-driver = final.callPackage ./packages/nvidia-driver.nix { };
    nvidia-prefetch = final.callPackage ./packages/nvidia-prefetch.nix { };
  };
in
inputs.nixpkgs.lib.fixedPoints.composeManyExtensions [
  # Establish the independent package sets before overlays that inspect or
  # extend the final package set. This keeps stdenv evaluation acyclic on
  # custom platform bootstraps such as nixos-raspberrypi.
  unstableOverlay
  stableOverlay
  eupkgsOverlay
  localPackagesOverlay
  inputs.nix4vscode.overlays.default
]
