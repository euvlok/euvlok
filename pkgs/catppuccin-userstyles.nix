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
  version = "all-userstyles-export-unstable-2026-01-16";

  src = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "userstyles";
    rev = "a705c3166765be722f0d33d34a411b4aa2663169";
    hash = "sha256-GlhBDOcaNADurl6NrmNGFk4MTf5wpoilzj74JCb04rA=";
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

    deno run --allow-read --allow-write --allow-net --allow-env ./scripts/stylus-import/main.ts
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
