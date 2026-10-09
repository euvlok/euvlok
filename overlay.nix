{
  inputs,
  hostPlatform ? null,
  buildPlatform ? hostPlatform,
  unstableSource ? inputs.nixpkgs-unstable-small,
  localPackagesOverlay ? inputs.self.overlays.packages,
}:
let
  fixCudaOutputPropagation =
    package:
    if
      inputs.nixpkgs.lib.isDerivation package && builtins.isList (package.propagatedBuildOutputs or null)
    then
      package.overrideAttrs (old: {
        # Clear CUDA's array before exporting space-separated output names
        preFixup = (old.preFixup or "") + ''
          fixupPropagatedBuildOutputsForMultipleOutputs() {
            local outputNames="''${propagatedBuildOutputs[*]}"
            unset propagatedBuildOutputs
            export propagatedBuildOutputs="$outputNames"
          }
        '';
      })
    else
      package;

  packageFixesOverlay = _final: prev: {
    pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
      (_pythonFinal: pythonPrev: {
        anyio =
          if pythonPrev.anyio.version == "4.14.2" then
            pythonPrev.anyio.overridePythonAttrs (old: {
              # Preserve server-side wrapping when Python rejects client-only
              # hostnames, including Python 3.12.15, 3.13.16, and 3.14.8
              postPatch = (old.postPatch or "") + ''
                substituteInPlace src/anyio/streams/tls.py \
                  --replace-fail 'if hostname is not None:' \
                  'if hostname is not None and not server_side:'
              '';
            })
          else
            pythonPrev.anyio;
      })
    ];
    cudaPackages = prev.cudaPackages.overrideScope (
      _cudaFinal: cudaPrev: builtins.mapAttrs (_: fixCudaOutputPropagation) cudaPrev
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

  # Extend only the callPackage scope for eupkgs instead of rebuilding the
  # complete unstable Nixpkgs fixed point
  eupkgsOverlay =
    final: _prev:
    let
      base = final.unstable;
      additions = upstreamAdditions // {
        # Keep newer Nixpkgs sources paired with their own node_modules
        opencode =
          if
            inputs.nixpkgs.lib.versionAtLeast base.opencode.version upstreamAdditions.opencode.upstreamVersion
          then
            base.opencode
          else
            upstreamAdditions.opencode;
      };
      scoped = base // additions // { callPackage = base.newScope additions; };
      upstreamAdditions = inputs.eupkgs.overlays.default scoped base;
    in
    {
      eupkgs = scoped;
    };
in
inputs.nixpkgs.lib.fixedPoints.composeManyExtensions [
  # Establish the independent package sets before overlays that inspect or
  # extend the final package set. This keeps stdenv evaluation acyclic on
  # custom platform bootstraps such as nixos-raspberrypi.
  unstableOverlay
  eupkgsOverlay
  packageFixesOverlay
  localPackagesOverlay
  (final: _prev: {
    euvlokVscodeExtensions =
      { version, extensions }:
      import (inputs.nix4vscode + /nix/forVscodeVersionRaw.nix) {
        inherit extensions version;
        pkgs = final.unstable;
      };
  })
  inputs.nix4vscode.overlays.default
]
