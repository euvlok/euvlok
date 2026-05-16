{
  pkgs,
  lib,
  config,
  ...
}:
let
  languageDefinitions = import ./catalog { inherit pkgs lib; };
  enabledLanguages = lib.attrsets.filterAttrs (
    name: _: config.hm.languages.${name}.enable or false
  ) languageDefinitions;
  collectLists =
    selector: lib.lists.flatten (lib.attrsets.mapAttrsToList (_: def: selector def) enabledLanguages);
  mergeAttrs =
    selector:
    lib.attrsets.mergeAttrsList (lib.attrsets.mapAttrsToList (_: def: selector def) enabledLanguages);
in
{
  config = lib.modules.mkIf config.hm.helix.enable {
    programs.helix.languages.language-server = mergeAttrs (def: def.helix.languageServers or { });
    programs.helix.languages.language = collectLists (def: def.helix.languages or [ ]);
  };
}
