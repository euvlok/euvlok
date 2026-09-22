{ enabledLanguages, enabledLanguagePackages }:
{
  lib,
  config,
  ...
}:
{
  config = lib.modules.mkIf config.euvlok.home.zed-editor.enable {
    programs.zed-editor = {
      extensions =
        lib.lists.optional config.programs.fish.enable "fish"
        ++ lib.lists.concatMap (def: def.zed.extensions or [ ]) (lib.attrsets.attrValues enabledLanguages);
      extraPackages = enabledLanguagePackages;
      userSettings = lib.modules.mkMerge (
        lib.attrsets.mapAttrsToList (_: def: {
          languages = def.zed.languages or { };
          lsp = def.zed.lsp or { };
        }) enabledLanguages
      );
    };
  };
}
