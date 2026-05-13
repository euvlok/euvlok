{
  pkgs,
  lib,
  versionMappings,
  getLatestVersion,
  prettierFormatter,
}:
{
  packages = builtins.attrValues { inherit (pkgs.unstable) flutter; };
  vscode.extensions = [
    "dart-code.dart-code"
    "dart-code.flutter"
  ];
  vscode.settings."[dart]" = {
    editor.defaultFormatter = "dart-code.dart-code";
    editor.formatOnSave = true;
    editor.codeActionsOnSave = {
      source.fixAll = "explicit";
      source.organizeImports = "explicit";
    };
  };
  helix.languageServers.dart = {
    command = "dart";
    args = [
      "language-server"
      "--protocol=lsp"
    ];
  };
  helix.languages = [
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
    path = "dart";
    arguments = [
      "language-server"
      "--protocol=lsp"
    ];
  };
}
