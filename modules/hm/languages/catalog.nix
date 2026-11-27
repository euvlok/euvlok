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
          "10"
          "11"
        ];
      in
      lib.attrsets.genAttrs versions (version: pkgs.unstable.dotnetCorePackages."sdk_${version}_0-bin");
  };

  /**
    Return the highest version key in a non-empty package mapping

    # Inputs

    `mapping`
    : Non-empty attribute set keyed by Nix-comparable version strings

    # Type
    ```
    getLatestVersion :: AttrSet -> String
    ```

    # Examples
    :::{.example}
    ## `getLatestVersion` usage example
    ```nix
    getLatestVersion { "9" = null; "10" = null; }
    => "10"
    ```
    :::
  */
  getLatestVersion =
    mapping: lib.lists.last (lib.lists.sort lib.strings.versionOlder (lib.attrsets.attrNames mapping));

  /**
    Configure MitOS to format the current buffer with Prettier

    # Inputs

    `parser`
    : Prettier parser name. `prettier` must be on the editor's PATH

    # Type
    ```
    prettierFormatter :: String -> AttrSet
    ```

    # Examples
    :::{.example}
    ## `prettierFormatter` usage example
    ```nix
    (prettierFormatter "json").external.arguments
    => [ "--parser" "json" "--stdin-filepath" "{buffer_path}" ]
    ```
    :::
  */
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
in
lib.filesystem.packagesFromDirectoryRecursive {
  directory = ./catalog;
  callPackage =
    file: _:
    import file {
      inherit
        pkgs
        lib
        versionMappings
        getLatestVersion
        prettierFormatter
        ;
    };
}
