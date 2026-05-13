{
  pkgs,
  lib,
  versionMappings,
  getLatestVersion,
  prettierFormatter,
}:
{
  packages = builtins.attrValues { inherit (pkgs.unstable) nim nimlsp; };
  vscode.extensions = [
    "nimLang.nimlang"
    "nimsaem.nimvscode"
  ];
  vscode.settings."[nim]" = {
    editor.defaultFormatter = "kosz78.nim";
    editor.formatOnSave = true;
  };
  helix.languageServers.nimlangserver.command = "nimlangserver";
  helix.languages = [
    {
      name = "nim";
      auto-format = true;
      language-servers = [ "nimlangserver" ];
    }
  ];
  zed.extensions = [ "nim" ];
  zed.languages."Nim".language_servers = [ "nimlsp" ];
  zed.lsp.nimlsp.binary.path = "nimlsp";
}
