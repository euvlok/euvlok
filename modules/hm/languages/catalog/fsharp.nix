{
  pkgs,
  lib,
  versionMappings,
  getLatestVersion,
  prettierFormatter,
}:
{
  packages = builtins.attrValues { inherit (pkgs.unstable) dotnet-sdk fsautocomplete; };
  vscode.extensions = [ "ionide.ionide-fsharp" ];
  vscode.settings."[fsharp]" = {
    editor.defaultFormatter = "ionide.ionide-fsharp";
    editor.formatOnSave = true;
  };
  helix.languageServers.fsautocomplete = {
    command = "fsautocomplete";
    args = [ "--background-service-enabled" ];
  };
  helix.languages = [
    {
      name = "fsharp";
      auto-format = true;
      language-servers = [ "fsautocomplete" ];
    }
  ];
  zed.extensions = [ "fsharp" ];
  zed.languages."F#" = {
    language_servers = [ "fsautocomplete" ];
  };
  zed.lsp.fsautocomplete.binary = {
    path = "fsautocomplete";
    arguments = [ "--background-service-enabled" ];
  };
}
