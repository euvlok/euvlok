{
  pkgs,
  lib,
  config,
  ...
}:
let
  languageDefinitions = import ./catalog { inherit pkgs lib; };
in
{
  imports = [
    ./helix.nix
    ./vscode.nix
    ./zed.nix
  ];

  options.hm.languages = lib.attrsets.mapAttrs (
    name: def:
    lib.options.mkOption {
      default = { };
      description = lib.options.mdDoc "Manages the development environment for the ${lib.strings.toSentenceCase name} language";
      type =
        if def ? versionMap then
          lib.types.submodule {
            options = {
              enable = lib.options.mkOption {
                type = lib.types.bool;
                default = false;
                description = lib.options.mdDoc "Enable the development environment and tools for ${lib.strings.toSentenceCase name}";
              };
              version = lib.options.mkOption {
                type = lib.types.enum (lib.attrsets.attrNames def.versionMap);
                default = def.defaultVersion;
                description = lib.options.mdDoc ''
                  Select the version of the ${lib.strings.toSentenceCase name} SDK to install

                  **Available versions:**
                  ${lib.strings.concatStringsSep "\n" (map (v: "- `${v}`") (lib.attrsets.attrNames def.versionMap))}

                  The default is `${def.defaultVersion}`
                '';
              };
              extraPackages = lib.options.mkOption {
                type = lib.types.listOf lib.types.package;
                default = [ ];
                description = lib.options.mdDoc ''
                  A list of extra packages to install alongside the standard ${lib.strings.toSentenceCase name} toolchain
                '';
              };
            };
          }
        else
          lib.types.submodule {
            options = {
              enable = lib.options.mkOption {
                type = lib.types.bool;
                default = false;
                description = lib.options.mdDoc "Enable the development environment and tools for ${lib.strings.toSentenceCase name}";
              };
              extraPackages = lib.options.mkOption {
                type = lib.types.listOf lib.types.package;
                default = [ ];
                description = lib.options.mdDoc ''
                  A list of extra packages to install alongside the standard ${lib.strings.toSentenceCase name} toolchain.
                '';
              };
            };
          };
    }
  ) languageDefinitions;

  config =
    let
      enabledLanguages = lib.attrsets.filterAttrs (
        name: _: config.hm.languages.${name}.enable or false
      ) languageDefinitions;

      enabledLanguagePackageLists = lib.attrsets.mapAttrsToList (
        name: def:
        let
          langCfg = config.hm.languages.${name};
          basePackages = def.packages or [ ];
          versionedPackage = if (def ? versionMap) then [ def.versionMap.${langCfg.version} ] else [ ];
          extraPkgs = langCfg.extraPackages;
        in
        basePackages ++ versionedPackage ++ extraPkgs
      ) enabledLanguages;
    in
    {
      # assertions = [
      #   {
      #     assertion = (config.hm.languages.haskell.enable && isLinux);
      #     message = "Haskell is currently not supported on macOS (Darwin)";
      #   }
      # ];

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
        ++ (lib.lists.flatten enabledLanguagePackageLists);
    };
}
