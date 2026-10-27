{
  inputs,
  hostPlatform ? null,
  buildPlatform ? hostPlatform,
  unstableSource ? inputs.nixpkgs-unstable-small,
  localPackagesOverlay ? inputs.self.overlays.packages,
}:
let
  stableOverlay = _final: prev: {
    stable = import inputs.nixpkgs-stable (
      packageSetArgs prev
      // {
        # Share host policy and GPU settings without unstable's option defaults
        config = inputs.nixpkgs.lib.attrsets.filterAttrs (
          name: _:
          builtins.elem name [
            "allowUnfree"
            "allowUnfreePredicate"
            "allowUnfreePackages"
            "allowInsecurePredicate"
            "permittedInsecurePackages"
            "allowBroken"
            "allowUnsupportedSystem"
            "cudaSupport"
            "cudaCapabilities"
            "cudaForwardCompat"
            "rocmSupport"
          ]
        ) (prev.config or { });
      }
    );
  };

  stableFallbacksOverlay =
    final: prev:
    {
      inherit (final.stable) black;
      rocmPackages = final.stable.rocmPackages.overrideScope (
        _rocmFinal: rocmPrev: {
          # AOTriton's attention API must match the current PyTorch package.
          inherit (prev.rocmPackages) aotriton;
          rocprofiler-sdk =
            if rocmPrev.rocprofiler-sdk.version == "7.2.3" then
              rocmPrev.rocprofiler-sdk.overrideAttrs (old: {
                # OpenMP can discover the profiler before glog initializes.
                patches = (old.patches or [ ]) ++ [
                  (
                    inputs.nixpkgs
                    + /pkgs/development/rocm-modules/rocprofiler-sdk/0009-rocprofiler-sdk-guard-ompt-auto-start.patch
                  )
                ];
              })
            else
              rocmPrev.rocprofiler-sdk;
        }
      );
      llama-cpp =
        if prev.llama-cpp.version == "0.6.0" then
          prev.llama-cpp.overrideAttrs (old: {
            # Large CPU pools make the tiny generated-model tests time out.
            postPatch = (old.postPatch or "") + ''
              substituteInPlace tests/CMakeLists.txt \
                --replace-fail 'ARGS --models "''${MODEL_DIR}"' \
                'ARGS --models "''${MODEL_DIR}" --threads 1 --threads-batch 1'
            '';
          })
        else
          prev.llama-cpp;
      clipcat =
        if prev.clipcat.version == "0.26.0" then
          prev.clipcat.overrideAttrs (old: {
            # Rust removed these lints; Clipcat's deny policy makes them fatal.
            postPatch = (old.postPatch or "") + ''
              sed -i \
                -e '/^[[:space:]]*no_mangle_generic_items[[:space:]]*=/d' \
                -e '/^[[:space:]]*repr_transparent_non_zst_fields[[:space:]]*=/d' \
                -e '/^[[:space:]]*elided_lifetimes_in_associated_constant[[:space:]]*=/d' \
                Cargo.toml
            '';
          })
        else
          prev.clipcat;
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (_pythonFinal: pythonPrev: {
          fastmcp-slim =
            if pythonPrev.fastmcp-slim.version == "3.4.7" then
              pythonPrev.fastmcp-slim.override {
                # FastMCP 3.4.7 needs MCP SDK 1.x; Nixpkgs defaults to 2.x.
                mcp = pythonPrev.mcp_1;
              }
            else
              pythonPrev.fastmcp-slim;
          torch =
            if pythonPrev.torch.version == "2.13.0" && (pythonPrev.torch.rocmSupport or false) then
              pythonPrev.torch.overridePythonAttrs (old: {
                # HIP's empty __noinline__ macro breaks GCC 16's <format>.
                # Parse <chrono> first in every GNU C++ source, including c10.
                postPatch = (old.postPatch or "") + ''
                  substituteInPlace CMakeLists.txt \
                    --replace-fail 'project(Torch CXX C)' \
                    'project(Torch CXX C)
                  add_compile_options("$<$<COMPILE_LANG_AND_ID:CXX,GNU>:-include;chrono>")'
                '';
              })
            else
              pythonPrev.torch;
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
    }
    //
      inputs.nixpkgs.lib.attrsets.optionalAttrs
        (prev.stdenv.hostPlatform.isLinux && prev.stdenv.hostPlatform.isAarch64)
        {
          inherit (final.stable)
            folly
            fizz
            wangle
            fbthrift
            fb303
            edencommon
            watchman
            ;
        }
    // inputs.nixpkgs.lib.attrsets.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
      inherit (final.stable) ffmpeg ffmpeg-headless ffmpeg-full;
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
        overlays = [
          stableOverlay
          stableFallbacksOverlay
        ];
      }
    );
  };

  # Extend only the callPackage scope for eupkgs instead of rebuilding the
  # complete unstable Nixpkgs fixed point
  eupkgsOverlay =
    final: _prev:
    let
      base = final.unstable;
      additions = inputs.eupkgs.overlays.default scoped base;
      scoped = base // additions // { callPackage = base.newScope additions; };
    in
    {
      eupkgs = scoped;
    };
in
inputs.nixpkgs.lib.fixedPoints.composeManyExtensions [
  # Establish the independent package sets before overlays that inspect or
  # extend the final package set. This keeps stdenv evaluation acyclic on
  # custom platform bootstraps such as nixos-raspberrypi.
  stableOverlay
  unstableOverlay
  eupkgsOverlay
  stableFallbacksOverlay
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
