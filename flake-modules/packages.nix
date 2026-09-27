{
  perSystem =
    { pkgs, ... }:
    let
      nvidia-driver = pkgs.callPackage ../packages/nvidia-driver.nix { };
    in
    {
      packages = {
        inherit nvidia-driver;
        nvidia-prefetch = pkgs.callPackage ../packages/nvidia-prefetch.nix {
          inherit nvidia-driver;
        };
      }
      // pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        catppuccin-gtk = pkgs.callPackage ../packages/catppuccin-gtk.nix { };
      };
    };
}
