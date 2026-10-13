{ lib, pkgs, ... }:
let
  sources = lib.trivial.importJSON ./source.json;
  architectures = {
    x86_64-linux = "linux-x86_64";
    aarch64-darwin = "mac";
  };
  generated = {
    inherit (sources) version;
    sources = lib.attrsets.mapAttrsToList (system: source: {
      inherit (source) url sha256;
      arch = architectures.${system};
      locale = "en-US";
    }) sources.platforms;
  };
  binary = pkgs.callPackage "${pkgs.path}/pkgs/applications/networking/browsers/firefox-bin" {
    inherit generated;
    applicationName = "Nightly";
  };
in
binary.overrideAttrs (old: {
  pname = "firefox-unbranded-bin-unwrapped";
  # Unbranded builds ship Nightly.app rather than Firefox.app
  installPhase = lib.strings.replaceStrings [ "mv Firefox*.app" ] [ "mv *.app" ] old.installPhase;
  meta = old.meta // {
    description = "Mozilla's prebuilt unbranded Firefox release";
    license = lib.licenses.mpl20;
    platforms = lib.attrsets.attrNames sources.platforms;
  };
  passthru = old.passthru // {
    unbranded = true;
    # Native fetchers can refresh both artifacts without a Darwin builder
    updateSources = lib.attrsets.mapAttrs (
      _: source:
      binary.overrideAttrs {
        src = pkgs.fetchurl { inherit (source) url sha256; };
      }
    ) sources.platforms;
    # Taskcluster discovery supplies URLs and a version; nix-update owns the
    # version and hash replacements in the existing JSON source pins
    updateScript = [
      (lib.meta.getExe pkgs.python3)
      ./discover.py
    ]
    ++ pkgs.nix-update-script {
      attrPath = "firefox-unbranded";
      extraArgs = [
        "--flake"
        "--override-filename=lib/firefox-unbranded/source.json"
        "--system=${pkgs.stdenvNoCC.buildPlatform.system}"
        "--subpackage=updateSources.x86_64-linux"
        "--subpackage=updateSources.aarch64-darwin"
      ];
    };
  };
})
