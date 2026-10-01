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
  # Bun writes each locked package as a single JSON array, with a trailing comma
  # Read its integrity directly so dependency updates also update the Nix source
  lockPrefix = "    \"usercss-meta\": ";
  lockLine =
    lib.lists.findFirst (lib.strings.hasPrefix lockPrefix)
      (throw "usercss-meta is missing from bun.lock")
      (lib.strings.splitString "\n" (builtins.readFile ../../bun.lock));
  usercssMetaLock = builtins.fromJSON (
    lib.strings.removeSuffix "," (lib.strings.removePrefix lockPrefix lockLine)
  );
  usercssMeta = fetchurl {
    url = "https://registry.npmjs.org/usercss-meta/-/usercss-meta-${packageJson.dependencies.usercss-meta}.tgz";
    hash =
      assert builtins.head usercssMetaLock == "usercss-meta@${packageJson.dependencies.usercss-meta}";
      builtins.elemAt usercssMetaLock 3;
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
