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
      lib,
      ...
    }:
    {
      # Use final so dependencies, including the pinned NVIDIA driver, follow
      # overrides made by consumers of the generated overlay
      overlayAttrs = {
        catppuccin-gtk-fausto = final.callPackage ../packages/catppuccin-gtk.nix { };
        catppuccin-userstyles = final.callPackage ../packages/catppuccin-userstyles { };
        linux-rt-upscaler = final.callPackage ../packages/linux-rt-upscaler.nix { };
        lsfg-vk = final.callPackage ../packages/lsfg-vk.nix {
          basePackage = final.callPackage (providerInputs.nixpkgs + /pkgs/by-name/ls/lsfg-vk/package.nix) { };
        };
        nvidia-driver = final.callPackage ../packages/nvidia-driver.nix { };
      }
      //
        lib.attrsets.optionalAttrs
          (
            (lib.trivial.importJSON ../lib/firefox-unbranded/source.json).platforms
              ? ${pkgs.stdenvNoCC.hostPlatform.system}
          )
          {
            firefox-unbranded = final.callPackage ../lib/firefox-unbranded/firefox-unbranded.nix { };
          }
      // lib.attrsets.optionalAttrs pkgs.stdenvNoCC.hostPlatform.isLinux {
        chatgpt = final.callPackage (import ../slop.nix).packages.chatgpt { };
      };

      # Keep the established flake package name and omit unsupported platforms
      packages =
        lib.attrsets.filterAttrs
          (
            _: package:
            lib.attrsets.isDerivation package && lib.meta.availableOn pkgs.stdenv.hostPlatform package
          )
          (
            lib.attrsets.removeAttrs config.overlayAttrs [ "catppuccin-gtk-fausto" ]
            // {
              catppuccin-gtk = config.overlayAttrs.catppuccin-gtk-fausto;
            }
          );
    };
}
