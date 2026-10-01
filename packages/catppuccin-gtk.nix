{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  bash,
  sassc,
  flavor ? "mocha",
  accent ? "mauve",
  size ? "standard",
  rimless ? false,
}:
let
  pname = "catppuccin-gtk-fausto";
  color = if flavor == "latte" then "Light" else "Dark";
  base =
    if flavor == "frappe" then
      "-Frappe"
    else if flavor == "macchiato" then
      "-Macchiato"
    else
      "";
  tweaks = lib.optionals (base != "") [ flavor ] ++ lib.optional rimless "rimless";
  themeName =
    "Catppuccin${base}-${lib.strings.toSentenceCase accent}-${color}"
    + lib.optionalString (size == "compact") "-Compact"
    + lib.optionalString rimless "-R";
in
lib.checkListOfEnum "${pname}: flavor"
  [
    "latte"
    "frappe"
    "macchiato"
    "mocha"
  ]
  [ flavor ]
  lib.checkListOfEnum
  "${pname}: accent"
  [
    "blue"
    "flamingo"
    "green"
    "lavender"
    "maroon"
    "mauve"
    "peach"
    "pink"
    "red"
    "rosewater"
    "sapphire"
    "sky"
    "teal"
    "yellow"
  ]
  [ accent ]
  lib.checkListOfEnum
  "${pname}: size"
  [
    "standard"
    "compact"
  ]
  [ size ]
  stdenvNoCC.mkDerivation
  {
    inherit pname;
    version = "unstable-2026-06-25";

    src = fetchFromGitHub {
      owner = "Fausto-Korpsvart";
      repo = "Catppuccin-GTK-Theme";
      rev = "a0f69cc33299dc97267c3507fe8a001aecc46b0f";
      hash = "sha256-bSEWm62EWHC9zcYA+YoQp2cuSFt2FDsjalapnjYdoYU=";
    };

    patches = [
      ./patches/catppuccin-gtk-accent.patch
      ./patches/catppuccin-gtk-rimless.patch
    ];

    nativeBuildInputs = [
      bash
      sassc
    ];
    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      cd themes
      HOME="$TMPDIR" BATCH_MODE=true bash ./install.sh \
        --dest "$out/share/themes" \
        --accent ${accent} \
        --mode ${lib.toLower color} \
        --size ${size} \
        ${lib.optionalString (tweaks != [ ]) "--tweaks ${lib.escapeShellArgs tweaks}"}
      runHook postInstall
    '';

    passthru = { inherit themeName; };

    meta = {
      description = "Catppuccin GTK theme by Fausto-Korpsvart";
      homepage = "https://github.com/Fausto-Korpsvart/Catppuccin-GTK-Theme";
      license = lib.licenses.gpl3Only;
      platforms = lib.platforms.linux;
    };
  }
