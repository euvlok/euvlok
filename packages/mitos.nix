{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  libgcc,
  installShellFiles,
  nix-update-script,
}:
let
  inherit (stdenvNoCC.hostPlatform) isLinux system;
  platforms = {
    aarch64-darwin = {
      target = "aarch64-macos";
      hash = "sha256-M6SoSeR2o+CXQaVYlwBbHF0RG4B0Q1p587u9zpcJyOM=";
    };
    aarch64-linux = {
      target = "aarch64-linux";
      hash = "sha256-tcXqH7HyLEDHyNbq2mWWMMlVC6HZWLwBi6ykf3iHWjg=";
    };
    x86_64-darwin = {
      target = "x86_64-macos";
      hash = "sha256-R0gh5ycYqgacwvTpA8v9vzFFNH2ayNVZ42Zyj02Qadw=";
    };
    x86_64-linux = {
      target = "x86_64-linux";
      hash = "sha256-CkzLsO2ixewMcCEJcNOh1flHFQEbCwP/+dkmlnWmc6g=";
    };
  };
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "mitos";
  version = "0.2.1";

  src = finalAttrs.passthru.releaseArchives.${system};

  nativeBuildInputs = [ installShellFiles ] ++ lib.lists.optional isLinux autoPatchelfHook;
  buildInputs = lib.lists.optionals isLinux [
    libgcc
    stdenv.cc.cc.lib
  ];

  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    # MitOS finds runtime assets next to the resolved executable
    install -Dm755 ms "$out/libexec/mitos/ms"
    mv runtime "$out/libexec/mitos/runtime"
    mkdir -p "$out/bin"
    ln -s ../libexec/mitos/ms "$out/bin/ms"

    install -Dm644 LICENSE "$out/share/licenses/mitos/LICENSE"
    installShellCompletion --cmd ms \
      --bash contrib/completion/ms.bash \
      --fish contrib/completion/ms.fish \
      --zsh contrib/completion/ms.zsh

    runHook postInstall
  '';

  passthru = {
    releaseArchives = lib.attrsets.mapAttrs (
      _:
      { target, hash }:
      fetchurl {
        url = "https://github.com/mitos-editor/mitos/releases/download/v${finalAttrs.version}/mitos-v${finalAttrs.version}-${target}.tar.xz";
        inherit hash;
      }
    ) platforms;
    # Expose all archives to nix-update without requiring builders for other systems
    updateSources = lib.attrsets.mapAttrs (
      _: src: finalAttrs.finalPackage.overrideAttrs { inherit src; }
    ) finalAttrs.passthru.releaseArchives;
    updateScript = nix-update-script {
      attrPath = "mitos";
      extraArgs = [
        "--flake"
        "--override-filename=packages/mitos.nix"
      ]
      ++ lib.attrsets.mapAttrsToList (platform: _: "--subpackage=updateSources.${platform}") platforms;
    };
  };

  meta = {
    description = "Prebuilt selection-first modal text editor";
    homepage = "https://mitos.computer";
    changelog = "https://redirect.github.com/mitos-editor/mitos/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mpl20;
    mainProgram = "ms";
    platforms = lib.attrsets.attrNames platforms;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
