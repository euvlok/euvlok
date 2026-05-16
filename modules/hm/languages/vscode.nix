{
  pkgs,
  config,
  lib,
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
  extensionStrings = lib.lists.unique (
    lib.lists.optionals
      (config.hm.languages.cpp.enable or config.hm.languages.rust.enable
        or config.hm.languages.swift.enable
      )
      [
        "vadimcn.vscode-lldb"
      ]
    ++ collectLists (def: def.vscode.extensions or [ ])
  );
in
{
  config = lib.modules.mkIf config.hm.vscode.enable {
    programs.vscode.profiles.default.extensions =
      pkgs.nix4vscode.forVscodeVersion config.programs.vscode.package.version extensionStrings;

    programs.vscode.profiles.default.userSettings = mergeAttrs (def: def.vscode.settings or { }) // {
      "[toml]" = {
        editor.defaultFormatter = "tamasfe.even-better-toml";
        editor.formatOnSave = true;
      };
      chat.disableAIFeatures = true;
    };
  };
}
