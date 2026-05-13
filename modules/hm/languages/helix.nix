{
  pkgs,
  lib,
  config,
  ...
}:
let
  languageDefinitions = import ./catalog { inherit pkgs lib; };
  enabledLanguages = lib.filterAttrs (
    name: _: config.hm.languages.${name}.enable or false
  ) languageDefinitions;
  collectLists = selector: lib.flatten (lib.mapAttrsToList (_: def: selector def) enabledLanguages);
  mergeAttrs =
    selector: lib.mergeAttrsList (lib.mapAttrsToList (_: def: selector def) enabledLanguages);
in
{
  config = lib.mkIf config.hm.helix.enable {
    programs.helix.languages.language-server = mergeAttrs (def: def.helix.languageServers or { });
    programs.helix.languages.language = collectLists (def: def.helix.languages or [ ]);
  };
}
