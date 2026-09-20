{ enabledLanguages, ... }:
{
  lib,
  config,
  ...
}:
let
  collectLists = selector: lib.lists.concatMap selector (lib.attrsets.attrValues enabledLanguages);
  mergeAttrs = selector: lib.attrsets.concatMapAttrs (_: selector) enabledLanguages;
in
{
  config = lib.modules.mkIf config.euvlok.home.helix.enable {
    programs.helix.languages.language-server = mergeAttrs (def: def.helix.languageServers or { });
    programs.helix.languages.language = collectLists (def: def.helix.languages or [ ]);
  };
}
