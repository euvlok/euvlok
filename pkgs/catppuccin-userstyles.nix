{
  pkgs,
  lib,
  flavor ? "frappe",
  accent ? "mauve",
  removeStyles ? [
    "gmail"
    "shinigami-eyes"
  ],
  ...
}:

let
  capitalizeFirst =
    str:
    let
      first = builtins.substring 0 1 str;
      rest = builtins.substring 1 (builtins.stringLength str) str;
    in
    (lib.strings.toUpper first) + rest;

  normalizedFlavor = capitalizeFirst (
    builtins.replaceStrings [ "frappe" ] [ "frappé" ] (lib.strings.toLower flavor)
  );

  normalizedAccent = capitalizeFirst (lib.strings.toLower accent);
in
assert
  builtins.replaceStrings [ "é" ] [ "e" ] (lib.strings.toLower normalizedFlavor)
  == lib.strings.toLower flavor;
assert lib.strings.toLower accent == lib.strings.toLower normalizedAccent;
pkgs.stdenvNoCC.mkDerivation (_: {
  pname = "catppuccin-userstyles";
  version = "all-userstyles-export-unstable-2025-07-07";

  src = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "userstyles";
    rev = "bc471f6afe486ff77a1561f61c5a97ef26302e2e";
    hash = "sha256-alkdG5E3y7eNNEc1sjhi0kVDHEC48AzSygUwXRndshA=";
  };

  buildInputs = builtins.attrValues { inherit (pkgs) deno; };

  preBuild = ''
    export DENO_DIR="$TMPDIR/deno"
    export XDG_CACHE_HOME="$TMPDIR/cache"
    export HOME="$TMPDIR/home"
    mkdir -p "$DENO_DIR"
    mkdir -p "$XDG_CACHE_HOME"
    mkdir -p "$HOME"
  '';

  buildPhase = ''
    runHook preBuild

    for style in ${lib.concatStringsSep " " removeStyles}; do
      rm -rf "./styles/$style/"
    done

    deno run --allow-read --allow-write --allow-net ./scripts/stylus-import/main.ts
    sed -i \
      -e 's/"default":"mocha"/"default":"'"${flavor}"'"/g' \
      -e 's/"default":"mauve"/"default":"'"${accent}"'"/g' \
      -e 's/mocha:Mocha\*"/'${flavor}':'"${normalizedFlavor}"'\*"/g' \
      -e 's/mauve:Mauve\*"/'${accent}':'"${normalizedAccent}"'\*"/g' \
      dist/import.json
      
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/dist"
    cp "dist/import.json" "$out/dist"
    runHook postInstall
  '';
})
