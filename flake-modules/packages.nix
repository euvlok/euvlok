{ providerInputs }:
{ config, ... }:
{
  imports = [ providerInputs.flake-parts.flakeModules.easyOverlay ];

  # easyOverlay owns the local overlay; the full overlay adds the independent
  # package sets and upstream fixes around it
  flake.overlays.packages = config.flake.overlays.default;

  perSystem =
    {
      config,
      final,
      pkgs,
      ...
    }:
    {
      # Use final so dependencies, including the pinned NVIDIA driver, follow
      # overrides made by consumers of the generated overlay
      overlayAttrs = {
        catppuccin-gtk-fausto = final.callPackage ../packages/catppuccin-gtk.nix { };
        catppuccin-userstyles = final.callPackage ../packages/catppuccin-userstyles { };
        linux-rt-upscaler = final.callPackage ../packages/linux-rt-upscaler.nix { };
        lsfg-vk = final.callPackage ../packages/lsfg-vk.nix { };
        nvidia-driver = final.callPackage ../packages/nvidia-driver.nix { };
        nvidia-prefetch = final.callPackage ../packages/nvidia-prefetch.nix { };
      }
      // pkgs.lib.attrsets.optionalAttrs pkgs.stdenvNoCC.hostPlatform.isLinux {
        chatgpt = final.callPackage (import ../slop.nix).packages.chatgpt { };
      };

      # Keep the established flake package name and omit unsupported platforms
      packages =
        pkgs.lib.filterAttrs
          (
            _: package:
            pkgs.lib.isDerivation package && pkgs.lib.meta.availableOn pkgs.stdenv.hostPlatform package
          )
          (
            removeAttrs config.overlayAttrs [ "catppuccin-gtk-fausto" ]
            // {
              catppuccin-gtk = config.overlayAttrs.catppuccin-gtk-fausto;
            }
          );
    };
}
