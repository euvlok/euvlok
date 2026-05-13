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
  config = lib.mkIf config.hm.zed-editor.enable {
    programs.zed-editor.extensions =
      lib.optionals config.programs.fish.enable [ "fish" ]
      ++ lib.optionals config.programs.nushell.enable [ "nu" ]
      ++ collectLists (def: def.zed.extensions or [ ]);

    programs.zed-editor.userSettings.languages = mergeAttrs (def: def.zed.languages or { });
    programs.zed-editor.userSettings.lsp = mergeAttrs (def: def.zed.lsp or { });
  };
}
