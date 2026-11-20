{
  autoPatchelfHook,
  fetchurl,
  intellij-idea,
  lib,
  stdenv,
  unzip,
}:
let
  inherit (stdenv.hostPlatform) system;
  platforms = {
    aarch64-darwin = {
      suffix = "mac-arm64";
      rust = {
        release = "22407/1222265";
        hash = "sha256-6ujJLoGh7077adBa4GbjS3SLH0FKaqPU8JF8yDRYhWo=";
      };
      nativeDebug = {
        release = "12775/1212250";
        hash = "sha256-sfC9wb3BQpokOOMeyCFo2h4K4vdhNSdVIZ75zZxyqpM=";
      };
    };
    aarch64-linux = {
      suffix = "linux-arm64";
      rust = {
        release = "22407/1222263";
        hash = "sha256-9ZwhOVVnbB5ibuRWkrOQbr5EpFvPtRml6dnujR4qP5w=";
      };
      nativeDebug = {
        release = "12775/1212264";
        hash = "sha256-YI+bQwj0ionKFhg7lU4Y7XoG+mjfunf43MZGWn393GU=";
      };
    };
    x86_64-linux = {
      suffix = "linux-x86_64";
      rust = {
        release = "22407/1222259";
        hash = "sha256-tlD8ahqX7AiKquqwGqCU5icGHnv6BoaQMjGtBapMG3c=";
      };
      nativeDebug = {
        release = "12775/1212283";
        hash = "sha256-XcvquJxBE4yKUWPTuUDC3Q+8u2IMWsRuYwcxhWHzsWc=";
      };
    };
  };
  platform = platforms.${system};

  # The catalog lacks EmmyLua2 for IDEA 263 and omits the platform-specific
  # Rust and Native Debugging archives. Pin the compatible Marketplace builds
  plugins = {
    IntelliJ-EmmyLua2 = {
      version = "0.25.1.124-IDEA262";
      release = "25076/1224852";
      hash = "sha256-bZzmmpdeNKQP+TpovkT70RA2e16bK51xVvWK4s+mx88=";
      postPatch = ''
        chmod +x server/*/emmylua_ls
      '';
    };
    intellij-rust = platform.rust // {
      version = "263.7307.313-${platform.suffix}";
    };
    nativeDebug-plugin = platform.nativeDebug // {
      version = "263.7307.200-${platform.suffix}";
      # The Rust debugger toolchain supplies liblldb separately
      runtimeProvidedLibraries = [ "liblldb.so" ];
    };
  };
in
assert lib.assertMsg (
  lib.versions.major intellij-idea.buildNumber == "263"
  && lib.strings.versionAtLeast intellij-idea.buildNumber "263.7307"
) "The pinned plugins require IntelliJ IDEA 263.7307 or later within build series 263";
lib.attrsets.mapAttrsToList (
  pname: plugin:
  stdenv.mkDerivation (finalAttrs: {
    inherit pname;
    inherit (plugin) version;
    src = fetchurl {
      url = "https://downloads.marketplace.jetbrains.com/files/${plugin.release}/${pname}-${finalAttrs.version}.zip";
      inherit (plugin) hash;
    };
    nativeBuildInputs = [ unzip ] ++ lib.lists.optional stdenv.hostPlatform.isLinux autoPatchelfHook;
    buildInputs = lib.lists.optional stdenv.hostPlatform.isLinux (lib.attrsets.getLib stdenv.cc.cc);
    autoPatchelfIgnoreMissingDeps = plugin.runtimeProvidedLibraries or [ ];
    postPatch = plugin.postPatch or "";
    dontBuild = true;
    dontStrip = true;
    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -r . "$out"
      runHook postInstall
    '';
  })
) plugins
