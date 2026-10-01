{
  perSystem =
    { pkgs, ... }:
    let
      nvidia-driver = pkgs.callPackage ../packages/nvidia-driver.nix { };
      localPackages = {
        inherit nvidia-driver;
        nvidia-prefetch = pkgs.callPackage ../packages/nvidia-prefetch.nix {
          inherit nvidia-driver;
        };
        catppuccin-gtk = pkgs.callPackage ../packages/catppuccin-gtk.nix { };
        linux-rt-upscaler = pkgs.callPackage ../packages/linux-rt-upscaler.nix { };
        lsfg-vk = pkgs.callPackage ../packages/lsfg-vk.nix { };
      };
    in
    {
      packages = pkgs.lib.filterAttrs (
        _: package: pkgs.lib.meta.availableOn pkgs.stdenv.hostPlatform package
      ) localPackages;
    };
}
