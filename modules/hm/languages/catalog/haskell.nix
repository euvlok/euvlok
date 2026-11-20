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
