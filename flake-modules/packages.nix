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
      };
    };
}
