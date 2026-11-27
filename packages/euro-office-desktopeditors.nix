{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  gst_all_1,
  undmg,
  upstream,
}:
let
  inherit (stdenvNoCC) hostPlatform;
in
if hostPlatform.system == "aarch64-darwin" then
  upstream.override {
    # Replace the Linux FHS wrapper without evaluating its dependencies
    buildFHSEnv =
      upstreamAttrs:
      stdenvNoCC.mkDerivation (finalAttrs: {
        inherit (upstreamAttrs finalAttrs) pname version;

        src = fetchurl {
          url = "https://github.com/Euro-Office/DesktopEditors/releases/download/v${finalAttrs.version}/Euro-Office-DesktopEditors-${finalAttrs.version}-0-macos-arm64.dmg";
          hash = "sha256-qYy8aSf3rblGl9ntLDoYaV6rl6Dahg0on4BxXODllrU=";
        };

        nativeBuildInputs = [ undmg ];
        sourceRoot = ".";
        dontConfigure = true;
        dontBuild = true;
        dontFixup = true;

        installPhase = ''
          runHook preInstall
          mkdir -p "$out/Applications"
          mv Euro-Office.app "$out/Applications/"
          runHook postInstall
        '';

        meta = (lib.attrsets.removeAttrs (upstreamAttrs finalAttrs).meta [ "mainProgram" ]) // {
          platforms = [ "aarch64-darwin" ];
        };
      });
  }
else if hostPlatform.system == "aarch64-linux" then
  # Keep the Debian packaging and FHS wrapper for the ARM64 binary
  (upstream.override {
    fetchurl =
      args:
      fetchurl (
        args
        // {
          url = lib.strings.replaceStrings [ "_amd64.deb" ] [ "_arm64.deb" ] args.url;
          hash = "sha256-ax6zz6DzWzExK2TKxOVu6oxM/OXQNJziiIgT/M+giDY=";
        }
      );
    stdenv = stdenv // {
      mkDerivation =
        args:
        (stdenv.mkDerivation args).overrideAttrs (old: {
          # The ARM64 Qt media plugin links against GStreamer Bad libraries
          buildInputs = old.buildInputs ++ [ gst_all_1.gst-plugins-bad ];
        });
    };
  }).overrideAttrs
    (old: {
      meta = old.meta // {
        platforms = old.meta.platforms ++ [ "aarch64-linux" ];
      };
    })
else
  upstream
