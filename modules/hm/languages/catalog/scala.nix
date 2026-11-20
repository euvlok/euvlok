{ lib, pkgs, ... }:
{
  packages = lib.attrsets.attrValues {
    inherit (pkgs.unstable)
      scala
      sbt
      metals
      scalafmt
      ;
  };
  helix.languageServers.metals.command = "metals";
  helix.languages = [
    {
      name = "scala";
      auto-format = true;
      language-servers = [ "metals" ];
    }
  ];
  zed.extensions = [ "scala" ];
  zed.languages."Scala" = {
    language_servers = [ "metals" ];
    formatter = "language_server";
  };
  zed.lsp.metals.binary.path = lib.meta.getExe pkgs.unstable.metals;
}
