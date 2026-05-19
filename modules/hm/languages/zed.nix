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
  collectPackageLists = lib.attrsets.mapAttrsToList (
    name: def:
    let
      langCfg = config.hm.languages.${name};
      versionedPackage = if (def ? versionMap) then [ def.versionMap.${langCfg.version} ] else [ ];
    in
    (def.packages or [ ]) ++ versionedPackage ++ langCfg.extraPackages
  ) enabledLanguages;
  collectLists =
    selector: lib.lists.flatten (lib.attrsets.mapAttrsToList (_: def: selector def) enabledLanguages);
  mergeAttrs =
    selector:
    lib.attrsets.mergeAttrsList (lib.attrsets.mapAttrsToList (_: def: selector def) enabledLanguages);
in
{
  config = lib.modules.mkIf config.hm.zed-editor.enable {
    programs.zed-editor.extensions =
      lib.lists.optionals config.programs.fish.enable [ "fish" ]
      ++ lib.lists.optionals config.programs.nushell.enable [ "nu" ]
      ++ collectLists (def: def.zed.extensions or [ ]);

    programs.zed-editor.extraPackages = lib.lists.flatten collectPackageLists;
    programs.zed-editor.userSettings.languages = mergeAttrs (def: def.zed.languages or { });
    programs.zed-editor.userSettings.lsp = mergeAttrs (def: def.zed.lsp or { });
  };
}
