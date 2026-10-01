{ inputs }:
{
  mkNixpkgsOverlay =
    {
      hostPlatform ? null,
      buildPlatform ? hostPlatform,
      unstableSource ? inputs.nixpkgs-unstable-small,
    }:
    import ../overlay.nix {
      inherit
        inputs
        hostPlatform
        buildPlatform
        unstableSource
        ;
    };
}
