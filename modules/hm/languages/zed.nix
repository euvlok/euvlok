{ enabledLanguages, enabledLanguagePackages }:
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
  config = lib.modules.mkIf config.euvlok.home.zed-editor.enable {
    programs.zed-editor.extensions =
      lib.lists.optional config.programs.fish.enable "fish"
      ++ collectLists (def: def.zed.extensions or [ ]);

    programs.zed-editor.extraPackages = enabledLanguagePackages;
    programs.zed-editor.userSettings.languages = mergeAttrs (def: def.zed.languages or { });
    programs.zed-editor.userSettings.lsp = mergeAttrs (def: def.zed.lsp or { });
  };
}
