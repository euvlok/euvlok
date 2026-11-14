{ lib, pkgs, ... }:
{
  packages = lib.attrsets.attrValues { inherit (pkgs.unstable) sbcl; };
  vscode.extensions = [ "mattn.lisp" ];
  vscode.settings."[lisp]"."editor.formatOnSave" = true;
  zed.extensions = [
    "scheme"
    "elisp"
  ];
}
