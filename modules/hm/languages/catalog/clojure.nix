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
