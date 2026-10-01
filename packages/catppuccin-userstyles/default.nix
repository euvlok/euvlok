{
  lib,
  stdenvNoCC,
  bun,
  fetchurl,
  git,
  makeWrapper,
}:
let
  packageJson = lib.importJSON ./package.json;
  usercssMeta = fetchurl {
    url = "https://registry.npmjs.org/usercss-meta/-/usercss-meta-${packageJson.dependencies.usercss-meta}.tgz";
    # Match the runtime dependency's integrity in bun.lock
    hash = "sha512-zKrXCKdpeIwtVe87omxGo9URf+7mbozduMZEg79dmT4KB3XJwfIkEi/Uk0PcTwR/nZLtAK1+k7isgbGB/g6E7Q==";
  };
in
stdenvNoCC.mkDerivation {
  pname = "catppuccin-userstyles";
  inherit (packageJson) version;

  src = lib.fileset.toSource {
    root = ./.;
    fileset = ./build.ts;
  };

  nativeBuildInputs = [
    bun
    makeWrapper
  ];
  strictDeps = true;

  buildPhase = ''
    runHook preBuild
    mkdir -p node_modules/usercss-meta
    tar -xzf ${usercssMeta} -C node_modules/usercss-meta --strip-components=1
    bun build build.ts --target=bun --outfile=catppuccin-userstyles.js
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm644 catppuccin-userstyles.js "$out/lib/catppuccin-userstyles.js"
    install -Dm644 ${../../LICENSE} "$out/share/licenses/catppuccin-userstyles/LICENSE"
    install -Dm644 node_modules/usercss-meta/LICENCE \
      "$out/share/licenses/catppuccin-userstyles/usercss-meta.LICENCE"
    makeWrapper ${lib.getExe bun} "$out/bin/catppuccin-userstyles" \
      --add-flags "$out/lib/catppuccin-userstyles.js" \
      --prefix PATH : ${lib.makeBinPath [ git ]}
    runHook postInstall
  '';

  meta = {
    inherit (packageJson) description;
    homepage = "https://github.com/euvlok/euvlok";
    license = lib.licenses.mit;
    mainProgram = "catppuccin-userstyles";
    inherit (bun.meta) platforms;
  };
}
