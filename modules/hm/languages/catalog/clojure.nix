{ pkgs, ... }:
{
  packages = builtins.attrValues {
    inherit (pkgs.unstable)
      clojure
      leiningen
      clj-kondo
      babashka
      ;
  };
  vscode.extensions = [ "betterthantomorrow.calva" ];
  vscode.settings."[clojure]" = {
    editor.defaultFormatter = "betterthantomorrow.calva";
    editor.formatOnSave = true;
  };
  helix.languageServers.clojure-lsp.command = "clojure-lsp";
  helix.languages = [
    {
      name = "clojure";
      auto-format = true;
      language-servers = [ "clojure-lsp" ];
    }
  ];
  zed.extensions = [ "clojure" ];
  zed.languages."Clojure" = { };
}
