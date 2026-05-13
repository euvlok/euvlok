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

  options.hm.languages = lib.mapAttrs (
    name: def:
    lib.mkOption {
      default = { };
      description = lib.options.mdDoc "Manages the development environment for the ${lib.strings.toSentenceCase name} language";
      type =
        if def ? versionMap then
          lib.types.submodule {
            options = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = lib.options.mdDoc "Enable the development environment and tools for ${lib.strings.toSentenceCase name}";
              };
              version = lib.mkOption {
                type = lib.types.enum (lib.attrNames def.versionMap);
                default = def.defaultVersion;
                description = lib.options.mdDoc ''
                  Select the version of the ${lib.strings.toSentenceCase name} SDK to install

                  **Available versions:**
                  ${lib.concatStringsSep "\n" (map (v: "- `${v}`") (lib.attrNames def.versionMap))}

                  The default is `${def.defaultVersion}`
                '';
              };
              extraPackages = lib.mkOption {
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
              enable = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = lib.options.mdDoc "Enable the development environment and tools for ${lib.strings.toSentenceCase name}";
              };
              extraPackages = lib.mkOption {
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
      enabledLanguages = lib.filterAttrs (
        name: _: config.hm.languages.${name}.enable or false
      ) languageDefinitions;

      enabledLanguagePackageLists = lib.mapAttrsToList (
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
        ++ (lib.flatten enabledLanguagePackageLists);
    };
}
