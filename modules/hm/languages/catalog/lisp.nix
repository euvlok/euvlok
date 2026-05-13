{ pkgs, ... }:
{
  packages = builtins.attrValues { inherit (pkgs.unstable) sbcl; };
  vscode.extensions = [ "mattn.lisp" ];
  vscode.settings."[lisp]".editor.formatOnSave = true;
  helix.languageServers.cl-lsp.command = "cl-lsp";
  helix.languages = [
    {
      name = "common-lisp";
      auto-format = true;
      language-servers = [ "cl-lsp" ];
    }
  ];
  zed.extensions = [
    "scheme"
    "elisp"
  ];
}
