{
  pkgs,
  lib,
  versionMappings,
  getLatestVersion,
  prettierFormatter,
}:
{
  packages = builtins.attrValues { inherit (pkgs.unstable) kotlin kotlin-language-server gradle; };
  vscode.extensions = [ "fwcd.kotlin" ];
  vscode.settings."[kotlin]" = {
    editor.defaultFormatter = "fwcd.kotlin";
    editor.formatOnSave = true;
  };
  helix.languageServers.kotlin-language-server.command = "kotlin-language-server";
  helix.languages = [
    {
      name = "kotlin";
      auto-format = true;
      language-servers = [ "kotlin-language-server" ];
    }
  ];
  zed.extensions = [ "kotlin" ];
  zed.languages."Kotlin" = {
    language_servers = [ "kotlin-language-server" ];
    formatter = "language_server";
  };
  zed.lsp.kotlin-language-server.binary.path = "kotlin-language-server";
}
