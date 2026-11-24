{ lib, pkgs, ... }:
{
  packages = lib.attrsets.attrValues {
    inherit (pkgs.unstable)
      clojure
      leiningen
      clj-kondo
      clojure-lsp
      babashka
      ;
  };
  mitos.languageServers.clojure-lsp.command = "clojure-lsp";
  mitos.languages = [
    {
      name = "clojure";
      auto-format = true;
      language-servers = [ "clojure-lsp" ];
    }
  ];
  zed.extensions = [ "clojure" ];
  zed.languages."Clojure" = { };
}
