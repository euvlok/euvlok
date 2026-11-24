{ lib, pkgs, ... }:
{
  packages = lib.attrsets.attrValues {
    inherit (pkgs.unstable) perl perlnavigator;
    inherit (pkgs.unstable.perlPackages) PerlCritic PerlTidy;
  };
  mitos.languageServers.perlnavigator = {
    command = "perlnavigator";
    args = [ "--stdio" ];
  };
  mitos.languages = [
    {
      name = "perl";
      auto-format = true;
      language-servers = [ "perlnavigator" ];
    }
  ];
  zed.extensions = [ "perl" ];
  zed.languages."Perl".language_servers = [ "perlnavigator-server" ];
  zed.lsp.perlnavigator-server.binary = {
    path = lib.meta.getExe pkgs.unstable.perlnavigator;
    arguments = [ "--stdio" ];
  };
}
