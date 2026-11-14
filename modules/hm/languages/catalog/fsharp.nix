{
  lib,
  pkgs,
  versionMappings,
  getLatestVersion,
  ...
}:
{
  packages = lib.attrsets.attrValues {
    inherit (pkgs.unstable)
      fsautocomplete
      ilspycmd
      netcoredbg
      ;
  };
  versionMap = versionMappings.dotnet;
  defaultVersion = getLatestVersion versionMappings.dotnet;
  vscode.extensions = [ "ionide.ionide-fsharp" ];
  vscode.settings."[fsharp]" = {
    "editor.defaultFormatter" = "ionide.ionide-fsharp";
    "editor.formatOnSave" = true;
  };
  helix.languageServers.fsautocomplete = {
    command = "fsautocomplete";
    args = [ "--adaptive-lsp-server-enabled" ];
  };
  helix.languages = [
    {
      name = "fsharp";
      auto-format = true;
      language-servers = [ "fsautocomplete" ];
    }
  ];
  zed.extensions = [ "fsharp" ];
  zed.languages."FSharp" = {
    language_servers = [ "fsautocomplete" ];
  };
  zed.lsp.fsautocomplete.binary = {
    path = lib.meta.getExe pkgs.unstable.fsautocomplete;
    arguments = [ "--adaptive-lsp-server-enabled" ];
  };
}
