{
  lib,
  stdenvNoCC,
  fetchurl,
  _7zz,
}:

let
  version = "0.8.5.1";

  srcs = {
    aarch64-darwin = fetchurl {
      url = "https://github.com/imputnet/helium-macos/releases/download/${version}/helium_${version}_arm64-macos.dmg";
      hash = "sha256-erlRR3QTHvzNCSXcGtpR27d2ElNrrRvS7ZLHEnZK0wI=";
    };
    x86_64-darwin = fetchurl {
      url = "https://github.com/imputnet/helium-macos/releases/download/${version}/helium_${version}_x86_64-macos.dmg";
      hash = "sha256-eAmegvrsaGInBcQxsV+0wXOZ5o52s9Rz1l6Ol5td0fs=";
    };
  };
in
stdenvNoCC.mkDerivation {
  pname = "helium-browser";
  inherit version;
  src =
    srcs.${stdenvNoCC.hostPlatform.system}
      or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");

  sourceRoot = "Helium.app";

  nativeBuildInputs = [ _7zz ];

  unpackPhase = ''
    7zz x "$src" -snld
  '';

  dontFixup = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/Applications
    cp -R . $out/Applications/Helium.app
    runHook postInstall
  '';

  meta = {
    description = "Private, fast, and honest web browser based on ungoogled-chromium";
    homepage = "https://github.com/imputnet/helium-macos";
    license = lib.licenses.gpl3Only;
    platforms = [
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    maintainers = [ ];
  };
}
