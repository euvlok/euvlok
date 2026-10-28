{
  pkgs,
  lib,
  config,
  ...
}:
let
  catalog = import ./catalog { inherit pkgs lib; };
  languageType = lib.types.submodule (
    { name, config, ... }:
    let
      definition = catalog.${name} or { };
      displayName = lib.strings.toSentenceCase name;
      jsonType = (pkgs.formats.json { }).type;
      tomlType = (pkgs.formats.toml { }).type;
      # Default each leaf so overriding one setting preserves the rest
      defaultSettings = lib.attrsets.mapAttrsRecursive (_: lib.modules.mkDefault);
    in
    {
      options = {
        enable = lib.options.mkEnableOption "the ${displayName} development environment and tools";
        packages = lib.options.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
          description = "Standard ${displayName} toolchain packages";
        };
        extraPackages = lib.options.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
          description = "Extra packages to install alongside the ${displayName} toolchain";
        };
        helix = {
          languageServers = lib.options.mkOption {
            type = tomlType;
            default = { };
            description = "Helix language server definitions for ${displayName}";
          };
          languages = lib.options.mkOption {
            type = lib.types.listOf tomlType;
            default = [ ];
            description = "Helix language definitions for ${displayName}";
          };
        };
        vscode = {
          extensions = lib.options.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "VS Code extension IDs for ${displayName}";
          };
          settings = lib.options.mkOption {
            type = jsonType;
            default = { };
            description = "VS Code settings for ${displayName}";
          };
        };
        zed = {
          extensions = lib.options.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Zed extensions for ${displayName}";
          };
          languages = lib.options.mkOption {
            type = jsonType;
            default = { };
            description = "Zed language settings for ${displayName}";
          };
          lsp = lib.options.mkOption {
            type = jsonType;
            default = { };
            description = "Zed language server settings for ${displayName}";
          };
        };
        versions = lib.options.mkOption {
          type = lib.types.attrsOf lib.types.package;
          default = { };
          description = "Available ${displayName} SDK versions";
        };
        version = lib.options.mkOption {
          type = lib.types.nullOr (lib.types.enum (lib.attrsets.attrNames config.versions));
          default = definition.defaultVersion or null;
          description = "SDK version to install, or null for no additional SDK";
        };
      };

      config = {
        packages =
          (definition.packages or [ ])
          ++ lib.lists.optional (config.version != null) config.versions.${config.version};
        versions = lib.attrsets.mapAttrs (_: lib.modules.mkDefault) (definition.versionMap or { });
        helix = {
          languageServers = defaultSettings (definition.helix.languageServers or { });
          languages = definition.helix.languages or [ ];
        };
        vscode = {
          extensions = definition.vscode.extensions or [ ];
          settings = defaultSettings (definition.vscode.settings or { });
        };
        zed = {
          extensions = definition.zed.extensions or [ ];
          languages = defaultSettings (definition.zed.languages or { });
          lsp = defaultSettings (definition.zed.lsp or { });
        };
      };
    }
  );
  enabledLanguages = lib.attrsets.filterAttrs (
    _: language: language.enable
  ) config.euvlok.home.languages;
  enabledLanguagePackages = lib.lists.concatMap (
    language: language.packages ++ language.extraPackages
  ) (lib.attrsets.attrValues enabledLanguages);
in
{
  imports = [
    ./helix.nix
    ./vscode.nix
    (import ../../../slop.nix).homeManager.vscode
    ./zed.nix
  ];

  options.euvlok.home = {
    languages = lib.options.mkOption {
      type = lib.types.attrsOf languageType;
      default = { };
      description = "Language toolchains and their editor integrations";
    };
    languagePackages = lib.options.mkOption {
      type = lib.types.listOf lib.types.package;
      internal = true;
      readOnly = true;
      description = "Packages for enabled language toolchains and shared development tools";
    };
  };

  config = {
    euvlok.home.languages = lib.attrsets.mapAttrs (_: _: { }) catalog;
    euvlok.home.languagePackages =
      (lib.attrsets.attrValues {
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
    home.packages = config.euvlok.home.languagePackages;
  };
}
