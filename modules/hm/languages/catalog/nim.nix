{ pkgs, ... }:
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
  helix.languageServers.nimlsp.command = "nimlsp";
  helix.languages = [
    {
      name = "nim";
      auto-format = true;
      language-servers = [ "nimlsp" ];
    }
  ];
  zed.extensions = [ "nim" ];
  zed.languages."Nim".language_servers = [ "nimlsp" ];
  zed.lsp.nimlsp.binary.path = "nimlsp";
}
