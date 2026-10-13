{ pkgs, lib }:
let
  versionMappings = {
    java =
      let
        versions = [
          "8"
          "11"
          "17"
          "21"
          "25"
        ];
      in
      lib.attrsets.genAttrs versions (version: pkgs.unstable."jdk${version}");

    dotnet =
      let
        versions = [
          "8"
          "9"
          "10"
        ];
      in
      lib.attrsets.genAttrs versions (version: pkgs.unstable.dotnetCorePackages."sdk_${version}_0-bin");
  };

  getLatestVersion =
    mapping: lib.lists.last (lib.lists.sort lib.strings.versionOlder (lib.attrsets.attrNames mapping));

  prettierFormatter = parser: {
    external = {
      command = "prettier";
      arguments = [
        "--parser"
        parser
        "--stdin-filepath"
        "{buffer_path}"
      ];
    };
  };

  callLanguage =
    file:
    import file {
      inherit
        pkgs
        lib
        versionMappings
        getLatestVersion
        prettierFormatter
        ;
    };
in
lib.attrsets.mapAttrs'
  (
    name: _:
    lib.attrsets.nameValuePair (lib.strings.removeSuffix ".nix" name) (
      callLanguage (lib.path.append ./. name)
    )
  )
  (
    lib.attrsets.filterAttrs (
      name: type: type == "regular" && lib.strings.hasSuffix ".nix" name && name != "default.nix"
    ) (lib.filesystem.readDir ./.)
  )
