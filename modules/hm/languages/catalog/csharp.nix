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
      ilspycmd
      netcoredbg
      omnisharp-roslyn
      ;
  };
  versionMap = versionMappings.dotnet;
  defaultVersion = getLatestVersion versionMappings.dotnet;
  zed.extensions = [ "csharp" ];
  zed.languages."CSharp" = {
    language_servers = [ "omnisharp" ];
    code_actions_on_format = {
      "source.fixAll" = true;
      "source.organizeImports" = true;
    };
  };
  zed.lsp.omnisharp.binary = {
    path = lib.meta.getExe' pkgs.unstable.omnisharp-roslyn "OmniSharp";
    arguments = [ "-lsp" ];
  };
}
