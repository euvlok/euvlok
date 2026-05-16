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
{
  clojure = callLanguage ./clojure.nix;
  cpp = callLanguage ./cpp.nix;
  csharp = callLanguage ./csharp.nix;
  dart = callLanguage ./dart.nix;
  elixir = callLanguage ./elixir.nix;
  fsharp = callLanguage ./fsharp.nix;
  go = callLanguage ./go.nix;
  haskell = callLanguage ./haskell.nix;
  java = callLanguage ./java.nix;
  javascript = callLanguage ./javascript.nix;
  kotlin = callLanguage ./kotlin.nix;
  lisp = callLanguage ./lisp.nix;
  lua = callLanguage ./lua.nix;
  nim = callLanguage ./nim.nix;
  ocaml = callLanguage ./ocaml.nix;
  perl = callLanguage ./perl.nix;
  php = callLanguage ./php.nix;
  python = callLanguage ./python.nix;
  ruby = callLanguage ./ruby.nix;
  rust = callLanguage ./rust.nix;
  scala = callLanguage ./scala.nix;
  swift = callLanguage ./swift.nix;
  zig = callLanguage ./zig.nix;
}
