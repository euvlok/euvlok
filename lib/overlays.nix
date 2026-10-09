{ inputs }:
{
  mkNixpkgsOverlay =
    {
      hostPlatform ? null,
      buildPlatform ? hostPlatform,
      unstableSource ? inputs.nixpkgs-unstable-small,
      localPackagesOverlay ? inputs.self.overlays.packages,
    }:
    import ../overlay.nix {
      inherit
        inputs
        hostPlatform
        buildPlatform
        unstableSource
        localPackagesOverlay
        ;
    };
}
