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
    rocmPackages = prev.rocmPackages.overrideScope (
      _rocmFinal: rocmPrev: {
        hipblaslt =
          if rocmPrev.hipblaslt.version == "7.2.3" then
            let
              lib = inputs.nixpkgs.lib;
              targets = lib.sort builtins.lessThan (
                lib.intersectLists (rocmPrev.clr.localGpuTargets or rocmPrev.clr.gpuTargets) [
                  "gfx908"
                  "gfx90a"
                  "gfx942"
                  "gfx950"
                  "gfx1100"
                  "gfx1101"
                  "gfx1150"
                  "gfx1151"
                  "gfx1200"
                  "gfx1201"
                ]
              );
              base = rocmPrev.hipblaslt.overrideAttrs (old: {
                patches = (old.patches or [ ]) ++ [
                  ./patches/hipblaslt-streaming/hipblaslt-streaming.patch
                ];
              });
              # Carry the next solution index between cached architecture builds
              deviceLibraries =
                (lib.foldl'
                  (
                    state: target:
                    let
                      package = (base.override { gpuTargets = [ target ]; }).overrideAttrs (old: {
                        outputs = old.outputs ++ [ "device" ];
                        env =
                          (old.env or { })
                          // {
                            TENSILE_RECORD_SOLUTION_INDEX = "1";
                          }
                          // lib.optionalAttrs (state.previous != null) {
                            TENSILE_SOLUTION_INDEX_START_FILE = "${state.previous}/.tensile-solution-index";
                          };
                        postInstall = (old.postInstall or "") + ''
                          mkdir -p "$device"
                          cp -r Tensile/library/. "$device/"
                        '';
                      });
                    in
                    {
                      previous = package.device;
                      libraries = state.libraries ++ [ "${target}=${package.device}" ];
                    }
                  )
                  {
                    previous = null;
                    libraries = [ ];
                  }
                  targets
                ).libraries;
            in
            if builtins.length targets <= 1 then
              base
            else
              base.overrideAttrs (old: {
                # Cache each architecture separately instead of retaining all
                # ten parsed libraries in one process on the hosted runner
                preBuild = (old.preBuild or "") + ''
                  python3 ${./patches/hipblaslt-streaming/hipblaslt-library-merge.py} \
                    Tensile/library ${lib.escapeShellArgs deviceLibraries}
                  touch device-library/Tensile.stamp
                '';
              })
          else
            rocmPrev.hipblaslt;
      }
    );
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
        black =
          if
            prev.stdenv.hostPlatform.isDarwin
            && pythonPrev.black.version == "26.5.1"
            && pythonPrev.pytest.version == "9.1.1"
          then
            pythonPrev.black.override {
              pytestCheckHook = pythonPrev.pytestCheckHook.override {
                pytest = pythonPrev.pytest.overridePythonAttrs (old: {
                  # Close pytest's cleanup iterator if traversal ends early
                  patches = (old.patches or [ ]) ++ [ ./patches/pytest-scandir/pytest-scandir.patch ];
                });
              };
            }
          else
            pythonPrev.black;
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
