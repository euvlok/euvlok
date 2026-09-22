{ enabledLanguages, ... }:
{
  lib,
  config,
  ...
}:
{
  config = lib.modules.mkIf config.euvlok.home.helix.enable {
    programs.helix.languages = lib.modules.mkMerge (
      lib.attrsets.mapAttrsToList (_: def: {
        language-server = def.helix.languageServers or { };
        language = def.helix.languages or [ ];
      }) enabledLanguages
    );
  };
}
