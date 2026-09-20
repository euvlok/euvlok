{
  pkgs,
  lib,
  config,
  ...
}:
let
  languageDefinitions = import ./catalog { inherit pkgs lib; };
  enabledLanguages = lib.attrsets.filterAttrs (
    name: _: config.euvlok.home.languages.${name}.enable or false
  ) languageDefinitions;

  enabledLanguagePackages = lib.lists.concatAttrValues (
    lib.attrsets.mapAttrs (
      name: def:
      let
        langCfg = config.euvlok.home.languages.${name};
      in
      (def.packages or [ ])
      ++ lib.lists.optional (def ? versionMap) def.versionMap.${langCfg.version}
      ++ langCfg.extraPackages
    ) enabledLanguages
  );

  editorModule =
    module:
    lib.modules.importApply module {
      inherit enabledLanguages enabledLanguagePackages;
    };
in
{
  imports = [
    (editorModule ./helix.nix)
    (editorModule ./vscode.nix)
    (editorModule ./zed.nix)
  ];

  options.euvlok.home.languages = lib.attrsets.mapAttrs (
    name: def:
    let
      displayName = lib.strings.toSentenceCase name;
    in
    lib.options.mkOption {
      default = { };
      description = "Manages the development environment for the ${displayName} language.";
      type = lib.types.submodule {
        options = {
          enable = lib.options.mkEnableOption "the ${displayName} development environment and tools";
          extraPackages = lib.options.mkOption {
            type = lib.types.listOf lib.types.package;
            default = [ ];
            description = "Extra packages to install alongside the standard ${displayName} toolchain.";
          };
        }
        // lib.attrsets.optionalAttrs (def ? versionMap) {
          version = lib.options.mkOption {
            type = lib.types.enum (lib.attrsets.attrNames def.versionMap);
            default = def.defaultVersion;
            description = ''
              Select the version of the ${displayName} SDK to install.

              **Available versions:**
              ${lib.strings.concatMapStringsSep "\n" (version: "- `${version}`") (
                lib.attrsets.attrNames def.versionMap
              )}

              The default is `${def.defaultVersion}`.
            '';
          };
        };
      };
    }
  ) languageDefinitions;

  config = {
    home.packages =
      (builtins.attrValues {
        inherit (pkgs.unstable)
          shellcheck
          shfmt
          bash-language-server
          taplo
          typos-lsp
          vscode-langservers-extracted
          yaml-language-server
          ;
      })
      ++ enabledLanguagePackages;
  };
}
