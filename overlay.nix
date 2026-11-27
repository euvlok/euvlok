{
  inputs,
  hostPlatform ? null,
  buildPlatform ? hostPlatform,
  unstableSource ? inputs.nixpkgs-unstable-small,
  localPackagesOverlay ? inputs.self.overlays.packages,
}:
let
  inherit (inputs.nixpkgs) lib;

  stableConfigKeys = lib.attrsets.genAttrs [
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
  ] (_: null);

  /**
    Add an independent stable package set with the parent's platform and
    selected policy and GPU settings, without inheriting unstable defaults

    # Inputs

    `final`
    : Unused final package set

    `prev`
    : Parent package set supplying platforms and configuration

    # Type

    ```
    stableOverlay :: Pkgs -> Pkgs -> { stable :: Pkgs; }
    ```

    # Examples
    :::{.example}
    ## Select a stable package

    ```nix
    (stableOverlay final prev).stable.black
    => the Black package from the stable pin
    ```

    :::
  */
  stableOverlay = _final: prev: {
    stable = import inputs.nixpkgs-stable (
      packageSetArgs prev
      // {
        # Share host policy and GPU settings without unstable's option defaults
        config = lib.attrsets.intersectAttrs stableConfigKeys (prev.config or { });
      }
    );
  };

  /**
    Apply version-gated upstream fixes and select stable dependencies on the
    platforms that need them

    # Inputs

    `final`
    : Final package set, including the `stable` layer and any overrides

    `prev`
    : Package set before these fixes

    # Type

    ```
    stableFallbacksOverlay :: Pkgs -> Pkgs -> AttrSet
    ```

    # Examples
    :::{.example}
    ## Use stable Black on all platforms

    ```nix
    (stableFallbacksOverlay final prev).black
    => final.stable.black
    ```

    :::
  */
  stableFallbacksOverlay =
    final: prev:
    {
      inherit (final.stable) black;
      clipcat =
        if prev.clipcat.version == "0.26.0" then
          prev.clipcat.overrideAttrs (old: {
            # https://redirect.github.com/NixOS/nixpkgs/pull/585611
            nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.pkg-config ];
            buildInputs = (old.buildInputs or [ ]) ++ [ final.libgit2 ];
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
      foundry =
        if prev.foundry.version == "1.8.6" then
          prev.foundry.overrideAttrs (old: {
            # https://redirect.github.com/NixOS/nixpkgs/pull/587157
            buildInputs = (old.buildInputs or [ ]) ++ [
              final.aws-lc
              final.rust-jemalloc-sys
              final.sqlite
              final.zstd
            ];
          })
        else
          prev.foundry;
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (_pythonFinal: pythonPrev: {
          fastmcp-slim =
            if
              pythonPrev.fastmcp-slim.version == "3.4.7" && lib.strings.versionAtLeast pythonPrev.mcp.version "2"
            then
              pythonPrev.fastmcp-slim.override {
                # FastMCP 3.4.7 needs MCP SDK 1.x, not the newer default
                mcp = pythonPrev.mcp_1;
              }
            else
              pythonPrev.fastmcp-slim;
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
      lib.attrsets.optionalAttrs (prev.stdenv.hostPlatform.isLinux && prev.stdenv.hostPlatform.isAarch64)
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
    // lib.attrsets.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
      inherit (final.stable) ffmpeg ffmpeg-headless ffmpeg-full;
      llvmPackages_latest =
        let
          llvm = prev.llvmPackages_latest;
        in
        if llvm.lldb.version == "23.1.3" then
          llvm
          // {
            lldb = llvm.lldb.overrideAttrs (old: {
              # xcrun cannot discover codesign inside the Darwin build sandbox
              cmakeFlags = (old.cmakeFlags or [ ]) ++ [
                (lib.strings.cmakeFeature "CMAKE_CODESIGN" (
                  lib.meta.getExe' prev.buildPackages.darwin.sigtool "codesign"
                ))
              ];
            });
          }
        else
          llvm;
      swiftPackages = prev.swiftPackages.overrideScope (
        _swiftFinal: swiftPrev: {
          swift-collections =
            if swiftPrev.swift-collections.version == "1.7.6" then
              swiftPrev.swift-collections.overrideAttrs (old: {
                # Reserve 0x200 bytes for the Span compatibility rpaths added in postInstall
                cmakeFlags = (old.cmakeFlags or [ ]) ++ [
                  (prev.lib.strings.cmakeFeature "CMAKE_SHARED_LINKER_FLAGS" "-Xlinker -headerpad -Xlinker 200")
                ];
              })
            else
              swiftPrev.swift-collections;
        }
      );
    };

  /**
    Select the local and optional cross platform for a secondary Nixpkgs
    import without inheriting the parent's elaborated platform records

    # Inputs

    `prev`
    : Parent package set supplying fallback build and host platforms

    # Type

    ```
    packageSetArgs :: Pkgs -> AttrSet
    ```

    # Examples
    :::{.example}
    ## Omit `crossSystem` on a native platform

    ```nix
    # With no platform overrides and a native x86_64 Linux package set
    packageSetArgs prev
    => { localSystem = "x86_64-linux"; }
    ```

    :::
  */
  packageSetArgs =
    prev:
    let
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

  /**
    Add an unstable package set using the parent's platforms and policy, then
    apply stable fallbacks inside that package set

    # Inputs

    `final`
    : Unused final package set

    `prev`
    : Parent package set supplying the fallback platforms and configuration

    # Type

    ```
    unstableOverlay :: Pkgs -> Pkgs -> { unstable :: Pkgs; }
    ```

    # Examples
    :::{.example}
    ## Access a stable fallback inside unstable

    ```nix
    (unstableOverlay final prev).unstable.black
    => (unstableOverlay final prev).unstable.stable.black
    ```

    :::
  */
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

  /**
    Expose eupkgs over unstable without rebuilding the Nixpkgs fixed point

    # Inputs

    `final`
    : Final package set, with an `unstable` layer to extend

    `prev`
    : Unused previous package set

    # Type

    ```
    eupkgsOverlay :: Pkgs -> Pkgs -> { eupkgs :: Pkgs; }
    ```

    # Examples
    :::{.example}
    ## Access a package carried through from unstable

    ```nix
    (eupkgsOverlay final prev).eupkgs.stdenv
    => final.unstable.stdenv
    ```

    :::
  */
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
lib.fixedPoints.composeManyExtensions [
  # Establish the independent package sets before overlays that inspect or
  # extend the final package set. This keeps stdenv evaluation acyclic on
  # custom platform bootstraps such as nixos-raspberrypi.
  stableOverlay
  unstableOverlay
  eupkgsOverlay
  stableFallbacksOverlay
  localPackagesOverlay
]
