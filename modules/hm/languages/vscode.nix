{ enabledLanguages, ... }:
{
  config,
  lib,
  ...
}:
let
  collectLists = selector: lib.lists.concatMap selector (lib.attrsets.attrValues enabledLanguages);
  mergeAttrs = selector: lib.attrsets.concatMapAttrs (_: selector) enabledLanguages;
  extensionStrings = lib.lists.unique (
    lib.lists.optional (
      config.euvlok.home.languages.cpp.enable
      || config.euvlok.home.languages.rust.enable
      || config.euvlok.home.languages.swift.enable
    ) "vadimcn.vscode-lldb"
    ++ collectLists (def: def.vscode.extensions or [ ])
  );
in
{
  config = lib.modules.mkIf config.euvlok.home.vscode.enable {
    euvlok.home.vscode.extensionIds = extensionStrings;

    programs.vscode.profiles.default.userSettings = mergeAttrs (def: def.vscode.settings or { }) // {
      "[toml]" = {
        editor.defaultFormatter = "tamasfe.even-better-toml";
        editor.formatOnSave = true;
      };
      chat.disableAIFeatures = true;
    };
  };
}
