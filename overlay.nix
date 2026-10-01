{
  inputs,
  hostPlatform ? null,
  buildPlatform ? hostPlatform,
  stableSource ? inputs.nixpkgs-stable,
  unstableSource ? inputs.nixpkgs-unstable-small,
}:
let
  fixCudaOutputPropagation =
    package:
    package.overrideAttrs (old: {
      # Clear CUDA's array before exporting space-separated output names
      preFixup = (old.preFixup or "") + ''
        fixupPropagatedBuildOutputsForMultipleOutputs() {
          local outputNames="''${propagatedBuildOutputs[*]}"
          unset propagatedBuildOutputs
          export propagatedBuildOutputs="$outputNames"
        }
      '';
    });

  packageFixesOverlay = _final: prev: {
    cudaPackages = prev.cudaPackages.overrideScope (
      _cudaFinal: cudaPrev: {
        libnpp = fixCudaOutputPropagation cudaPrev.libnpp;
      }
    );
    lazarus-qt6 = prev.lazarus-qt6.overrideAttrs (old: {
      # Removing rpaths leaves empty segments rejected by makeBinaryWrapper
      postInstall =
        builtins.replaceStrings
          [ "sed -re 's/-rpath [^ ]+//g'" ]
          [ "sed -re 's/-rpath [^ ]+//g' -e 's/ +/ /g; s/^ //; s/ $//'" ]
          old.postInstall;
    });
    nvtopPackages = prev.nvtopPackages // {
      full = prev.nvtopPackages.full.override {
        cudaPackages = prev.cudaPackages // {
          cuda_nvml_dev = fixCudaOutputPropagation prev.cudaPackages.cuda_nvml_dev;
        };
      };
    };
  };

  packageSetArgs =
    prev:
    let
      lib = inputs.nixpkgs.lib;
      # Keep secondary imports independent of the parent's elaborated platforms
      localSystem = if buildPlatform == null then prev.stdenvNoCC.buildPlatform.system else buildPlatform;
      targetSystem = if hostPlatform == null then prev.stdenvNoCC.hostPlatform.system else hostPlatform;
      isNative = lib.systems.equals (lib.systems.elaborate localSystem) (
        lib.systems.elaborate targetSystem
      );
    in
    {
      inherit localSystem;
    }
    # An explicit native crossSystem survives Nixpkgs' i686 re-import and turns
    # it back into x86_64, making multilib packages recurse into themselves
    // lib.attrsets.optionalAttrs (!isNative) { crossSystem = targetSystem; };

  # Keep the package-set layers independently readable even though consumers
  # normally install the composed overlay exported as `overlays.default`
  unstableOverlay = _final: prev: {
    unstable = import unstableSource (
      packageSetArgs prev
      // {
        config = prev.config or { };
        overlays = [ packageFixesOverlay ];
      }
    );
  };

  stableOverlay = _final: prev: {
    stable = import stableSource (
      packageSetArgs prev
      // {
        # Share package policy without feeding newer Nixpkgs' evaluated
        # defaults into older options whose types may have changed
        config = inputs.nixpkgs.lib.attrsets.filterAttrs (
          name: _:
          builtins.elem name [
            "allowUnfree"
            "allowUnfreePredicate"
            "allowBroken"
            "allowUnsupportedSystem"
            "allowInsecurePredicate"
            "permittedInsecurePackages"
            "checkMeta"
            "cudaSupport"
            "rocmSupport"
          ]
        ) (prev.config or { });
      }
    );
  };

  eupkgsOverlay = final: _prev: {
    eupkgs = final.unstable.extend (
      inputs.nixpkgs.lib.fixedPoints.composeManyExtensions [
        inputs.eupkgs.overlays.default
        (_final: prev: {
          # Keep newer Nixpkgs sources paired with their own node_modules
          opencode =
            if
              inputs.nixpkgs.lib.versionAtLeast final.unstable.opencode.version prev.opencode.upstreamVersion
            then
              final.unstable.opencode
            else
              prev.opencode;
        })
      ]
    );
  };

  localPackagesOverlay = final: _prev: {
    catppuccin-gtk-fausto = final.callPackage ./packages/catppuccin-gtk.nix { };
    catppuccin-userstyles = final.callPackage ./packages/catppuccin-userstyles { };
    euvlokVscodeExtensions =
      { version, extensions }:
      import (inputs.nix4vscode + /nix/forVscodeVersionRaw.nix) {
        inherit extensions version;
        pkgs = final.unstable;
      };
    linux-rt-upscaler = final.callPackage ./packages/linux-rt-upscaler.nix { };
    lsfg-vk = final.callPackage ./packages/lsfg-vk.nix { };
    nvidia-driver = final.callPackage ./packages/nvidia-driver.nix { };
    nvidia-prefetch = final.callPackage ./packages/nvidia-prefetch.nix { };
  };
in
inputs.nixpkgs.lib.fixedPoints.composeManyExtensions [
  # Establish the independent package sets before overlays that inspect or
  # extend the final package set. This keeps stdenv evaluation acyclic on
  # custom platform bootstraps such as nixos-raspberrypi.
  unstableOverlay
  stableOverlay
  eupkgsOverlay
  packageFixesOverlay
  localPackagesOverlay
  inputs.nix4vscode.overlays.default
]
