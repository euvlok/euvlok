{ inputs }:
{
  mkNixpkgsOverlay =
    {
      hostPlatform ? null,
      buildPlatform ? hostPlatform,
      stableSource ? inputs.nixpkgs-stable,
      unstableSource ? inputs.nixpkgs-unstable-small,
    }:
    import ../overlay.nix {
      inherit
        inputs
        hostPlatform
        buildPlatform
        stableSource
        unstableSource
        ;
    };
}
