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
  version = "all-userstyles-export-unstable-2026-02-05";

  src = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "userstyles";
    rev = "a6aca1e82039b55d7273deacfc04875d4e2f01db";
    hash = "sha256-QRzvMdBD3ySQ69VKQEXc174fZHm4ABG/0DtDTLuaezs=";
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
