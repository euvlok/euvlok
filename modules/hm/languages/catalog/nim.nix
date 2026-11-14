{ lib, pkgs, ... }:
{
  packages = lib.attrsets.attrValues { inherit (pkgs.unstable) nim nimlsp; };
  vscode.extensions = [
    "nimLang.nimlang"
    "nimsaem.nimvscode"
  ];
  vscode.settings."[nim]" = {
    "editor.defaultFormatter" = "nimLang.nimlang";
    "editor.formatOnSave" = true;
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
  zed.languages."Nim".language_servers = [ "nim" ];
  zed.lsp.nim.binary.path = lib.meta.getExe pkgs.unstable.nimlsp;
}
