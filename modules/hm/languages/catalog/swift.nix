{ pkgs, ... }:
{
  packages = builtins.attrValues { inherit (pkgs.unstable) swift swift-format sourcekit-lsp; };
  vscode.extensions = [
    "swift-server.swift"
    "vknabel.swift-coverage"
  ];
  vscode.settings."[swift]" = {
    editor.defaultFormatter = "swift-server.swift";
    editor.formatOnSave = true;
  };
  helix.languageServers.sourcekit-lsp.command = "sourcekit-lsp";
  helix.languages = [
    {
      name = "swift";
      auto-format = true;
      language-servers = [ "sourcekit-lsp" ];
    }
  ];
  zed.extensions = [
    "swift"
    "package-swift-lsp"
  ];
  zed.languages."Swift" = {
    language_servers = [ "sourcekit-lsp" ];
    formatter = "language_server";
  };
  zed.lsp.sourcekit-lsp.binary.path = "sourcekit-lsp";
}
