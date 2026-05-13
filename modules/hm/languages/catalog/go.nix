{
  pkgs,
  lib,
  versionMappings,
  getLatestVersion,
  prettierFormatter,
}:
{
  packages = builtins.attrValues {
    inherit (pkgs.unstable)
      go
      gopls
      golangci-lint
      delve
      air
      templ
      ;
  };
  vscode.extensions = [
    "golang.go"
    "premparihar.gotestexplorer"
  ];
  vscode.settings."[go]" = {
    editor.defaultFormatter = "golang.go";
    editor.formatOnSave = true;
    editor.codeActionsOnSave.source.organizeImports = "explicit";
  };
  helix.languageServers.gopls.command = "gopls";
  helix.languages = [
    {
      name = "go";
      auto-format = true;
      language-servers = [ "gopls" ];
    }
  ];
  zed.extensions = [
    "go-snippets"
    "golangci-lint"
    "gosum"
    "templ"
  ];
  zed.languages."Go" = {
    language_servers = [ "gopls" ];
    code_actions_on_format."source.organizeImports" = true;
    formatter = "language_server";
  };
  zed.lsp.gopls = {
    binary.path = "gopls";
    initialization_options = {
      gofumpt = true;
      staticcheck = true;
      vulncheck = "Imports";
      hints = {
        assignVariableTypes = true;
        compositeLiteralFields = true;
        compositeLiteralTypes = true;
        constantValues = true;
        functionTypeParameters = true;
        parameterNames = true;
        rangeVariableTypes = true;
      };
    };
  };
}
