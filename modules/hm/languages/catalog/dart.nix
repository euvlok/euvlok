{ lib, pkgs, ... }:
{
  packages = lib.attrsets.attrValues {
    inherit (pkgs.unstable) flutter;
    dart = pkgs.unstable.flutter.dart;
  };
  mitos.languageServers.dart = {
    command = "dart";
    args = [
      "language-server"
      "--protocol=lsp"
    ];
  };
  mitos.languages = [
    {
      name = "dart";
      auto-format = true;
      language-servers = [ "dart" ];
    }
  ];
  zed.extensions = [
    "dart"
    "flutter-snippets"
  ];
  zed.languages."Dart" = {
    language_servers = [ "dart" ];
    code_actions_on_format = {
      "source.fixAll" = true;
      "source.organizeImports" = true;
    };
    formatter = "language_server";
  };
  zed.lsp.dart.binary = {
    path = lib.meta.getExe pkgs.unstable.flutter.dart;
    arguments = [
      "language-server"
      "--protocol=lsp"
    ];
  };
}
