{
  lib,
  config,
  ...
}:
let
  enabledLanguages = lib.attrsets.filterAttrs (
    _: language: language.enable
  ) config.euvlok.home.languages;
in
{
  config = lib.modules.mkIf config.euvlok.home.mitos.enable {
    euvlok.home.mitos.languages = lib.modules.mkMerge (
      lib.attrsets.mapAttrsToList (_: def: {
        language-server = def.mitos.languageServers;
        language = def.mitos.languages;
      }) enabledLanguages
    );
  };
}
