{
  lib,
  pkgs,
  versionMappings,
  getLatestVersion,
  ...
}:
{
  packages = lib.attrsets.attrValues {
    inherit (pkgs.unstable)
      cfr
      gradle
      jdt-language-server
      maven
      ;
  };
  versionMap = versionMappings.java;
  defaultVersion = getLatestVersion versionMappings.java;
  zed.extensions = [
    "java"
  ];
  zed.languages."Java" = {
    language_servers = [ "jdtls" ];
    formatter = "language_server";
    prettier.allowed = false;
  };
  zed.lsp.jdtls.binary.path = lib.meta.getExe' pkgs.unstable.jdt-language-server "jdtls";
}
