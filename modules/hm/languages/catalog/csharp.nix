{
  pkgs,
  lib,
  versionMappings,
  getLatestVersion,
  prettierFormatter,
}:
{
  packages = builtins.attrValues { inherit (pkgs.unstable) omnisharp-roslyn netcoredbg; };
  versionMap = versionMappings.dotnet;
  defaultVersion = getLatestVersion versionMappings.dotnet;
  vscode.extensions = [
    "ms-dotnettools.csharp"
    "ms-dotnettools.csdevkit"
    "ms-dotnettools.vscode-dotnet-runtime"
  ];
  vscode.settings."[csharp]" = {
    editor.defaultFormatter = "ms-dotnettools.csharp";
    editor.formatOnSave = true;
    editor.codeActionsOnSave = {
      source.fixAll = "explicit";
      source.organizeImports = "explicit";
    };
  };
  zed.extensions = [ "csharp" ];
  zed.languages."CSharp" = {
    language_servers = [ "omnisharp" ];
    code_actions_on_format = {
      "source.fixAll" = true;
      "source.organizeImports" = true;
    };
  };
  zed.lsp.omnisharp.binary = {
    path = "OmniSharp";
    arguments = [ "-lsp" ];
  };
}
