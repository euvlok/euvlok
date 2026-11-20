{ inputs }:
{
  /**
    Compose the stable and unstable package sets, eupkgs, euvlok's package
    overrides and local packages, and the VS Code extension overlays

    If a platform is `null`, use the corresponding system string from the
    caller's package set. Secondary imports use `crossSystem` only when the
    platforms differ

    # Inputs

    `options` (attribute set)

    : `hostPlatform` (optional, default: `null`)
      : Target system, as a system string or Nixpkgs platform specification

      `buildPlatform` (optional, default: `hostPlatform`)
      : Build system, in the same form as `hostPlatform`

      `unstableSource` (optional, default: `inputs.nixpkgs-unstable-small`)
      : Importable Nixpkgs source for the unstable package set

      `localPackagesOverlay` (optional, default: `inputs.self.overlays.packages`)
      : Overlay applied after the package sets and package overrides

    # Type

    ```
    PlatformSpec = String | AttrSet
    Overlay = AttrSet -> AttrSet -> AttrSet
    mkNixpkgsOverlay :: {
      hostPlatform :: PlatformSpec | Null ? null;
      buildPlatform :: PlatformSpec | Null ? hostPlatform;
      unstableSource :: Path | AttrSet ? inputs.nixpkgs-unstable-small;
      localPackagesOverlay :: Overlay ? inputs.self.overlays.packages;
    } -> Overlay
    ```

    # Examples
    :::{.example}
    ## Use a custom local package overlay with the default package sets

    ```nix
    let
      pkgs = import inputs.nixpkgs {
        system = "x86_64-linux";
        overlays = [
          (mkNixpkgsOverlay {
            localPackagesOverlay = _final: _prev: { helloLocal = "local"; };
          })
        ];
      };
    in
    pkgs.helloLocal
    => "local"
    ```

    :::
  */
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
