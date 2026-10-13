{
  config,
  lib,
  ...
}:
let
  enabledLanguages = lib.attrsets.filterAttrs (
    _: language: language.enable
  ) config.euvlok.home.languages;
in
{
  config = lib.modules.mkIf config.euvlok.home.vscode.enable {
    euvlok.home.vscode.extensionIds =
      lib.lists.optional (
        config.euvlok.home.languages.cpp.enable
        || config.euvlok.home.languages.rust.enable
        || config.euvlok.home.languages.swift.enable
      ) "vadimcn.vscode-lldb"
      ++ lib.lists.concatMap (def: def.vscode.extensions or [ ]) (
        lib.attrsets.attrValues enabledLanguages
      );

    programs.vscode.profiles.default.userSettings = lib.modules.mkMerge (
      [
        {
          "[toml]" = {
            editor.defaultFormatter = "tamasfe.even-better-toml";
            editor.formatOnSave = true;
          };
        }
      ]
      ++ lib.attrsets.mapAttrsToList (_: def: def.vscode.settings or { }) enabledLanguages
    );
  };
}
