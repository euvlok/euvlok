{ lib, pkgs, ... }:
{
  packages = lib.attrsets.attrValues {
    inherit (pkgs.unstable)
      ghc
      cabal-install
      stack
      haskell-language-server
      hlint
      ormolu
      ;
  };
  vscode.extensions = [
    "haskell.haskell"
    "justusadam.language-haskell"
  ];
  vscode.settings."[haskell]" = {
    "editor.defaultFormatter" = "haskell.haskell";
    "editor.formatOnSave" = true;
  };
  helix.languageServers.haskell-language-server = {
    command = "haskell-language-server-wrapper";
    args = [ "--lsp" ];
  };
  helix.languages = [
    {
      name = "haskell";
      auto-format = true;
      language-servers = [ "haskell-language-server" ];
    }
  ];
  zed.extensions = [ "haskell" ];
  zed.languages."Haskell" = {
    language_servers = [ "hls" ];
    formatter = "language_server";
  };
  zed.lsp.hls.binary = {
    path = lib.meta.getExe' pkgs.unstable.haskell-language-server "haskell-language-server-wrapper";
    arguments = [ "--lsp" ];
  };
}
