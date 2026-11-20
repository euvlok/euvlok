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
      codex =
        if prev.codex.version == "0.167.0" then
          prev.codex.overrideAttrs (old: {
            # Cargo's system-library hook disables bundled copies of these dependencies.
            buildInputs = (old.buildInputs or [ ]) ++ [
              final.aws-lc
              final.oniguruma
              final.sqlite
              final.zstd
            ];
          })
        else
          prev.codex;
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
      telegram-desktop =
        if prev.telegram-desktop.version == "7.4.1" then
          prev.telegram-desktop.override {
            unwrapped = prev.telegram-desktop.unwrapped.overrideAttrs (old: {
              # Swift 6.4's library discovery expects a layout Nixpkgs does not use.
              postPatch = (old.postPatch or "") + ''
                substituteInPlace Telegram/cmake/telegram_apple_swift_runtime.cmake \
                  --replace-fail '--platform macosx' \
                  '--platform macosx --source-libraries "''${swift_bin_dir}/../lib/swift/macosx"'
              '';
            });
          }
        else
          prev.telegram-desktop;
      uutils-diffutils =
        if prev.uutils-diffutils.version == "0.6.0" then
          prev.uutils-diffutils.overrideAttrs (old: {
            # https://redirect.github.com/NixOS/nixpkgs/pull/587325
            # Use stdenv's GNU patch instead of its Homebrew name
            postPatch = (old.postPatch or "") + ''
              substituteInPlace src/utils.rs \
                --replace-fail '"gpatch"' '"patch"'
            '';
          })
        else
          prev.uutils-diffutils;
      llvmPackages_latest = prev.llvmPackages_latest // {
        lldb =
          if prev.llvmPackages_latest.lldb.version == "23.1.3" then
            prev.llvmPackages_latest.lldb.overrideAttrs (old: {
              # LLVM's xcrun fallback cannot find codesign in the build sandbox.
              cmakeFlags = (old.cmakeFlags or [ ]) ++ [
                "-DCMAKE_CODESIGN=${lib.meta.getExe' final.darwin.sigtool "codesign"}"
              ];
            })
          else
            prev.llvmPackages_latest.lldb;
      };
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
