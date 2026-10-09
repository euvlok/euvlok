{
  inputs,
  supportedSystems,
}:
_:
let
  euvlokLib = import ../lib { inherit inputs; };
in
{
  imports = [ inputs.flake-parts.flakeModules.touchup ];

  # Compose the public default after easyOverlay has generated its local layer
  # Its internal default stays local, so perSystem does not import the host
  # package-set layers merely to build a standalone package
  touchup.attr.overlays.attr.default.finish =
    localPackagesOverlay: euvlokLib.overlays.mkNixpkgsOverlay { inherit localPackagesOverlay; };

  flake = {
    lib = euvlokLib // {
      inherit supportedSystems;
    };
  };
}
