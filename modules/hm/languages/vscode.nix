{
  pkgs,
  config,
  lib,
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
  extensionStrings = lib.unique (
    lib.optionals
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
  config = lib.mkIf config.hm.vscode.enable {
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
