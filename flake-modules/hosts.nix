{
  config,
  lib,
  inputs,
  ...
}:
let
  inherit (lib)
    concatMapAttrs
    mapAttrs
    mapAttrs'
    mkOption
    nameValuePair
    types
    ;

  hostSpec = types.submodule (
    { ... }:
    {
      options = {
        path = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "Path to a Nix expression that returns this host configuration.";
        };

        output = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Attribute to select from the imported path. Defaults to the host name.";
        };

        configuration = mkOption {
          type = types.nullOr types.raw;
          default = null;
          description = "Pre-built configuration value. Useful for nested flakes or unusual inputs.";
        };
      };

      config.output = lib.modules.mkDefault null;
    }
  );

  userType = types.submodule {
    options = {
      nixosHosts = mkOption {
        type = types.attrsOf hostSpec;
        default = { };
        description = "NixOS hosts owned by this contributor.";
      };

      darwinHosts = mkOption {
        type = types.attrsOf hostSpec;
        default = { };
        description = "nix-darwin hosts owned by this contributor.";
      };

      homeConfigurations = mkOption {
        type = types.lazyAttrsOf types.raw;
        default = { };
        description = "Home Manager configurations or modules owned by this contributor.";
      };
    };
  };

  mergeUsers = attr: concatMapAttrs (_userName: user: user.${attr}) config.euvlok.users;

  mkHost =
    name: spec:
    if spec.configuration != null && spec.path != null then
      throw "euvlok host ${name} defines both `configuration` and `path`; choose one."
    else if spec.configuration != null then
      spec.configuration
    else if spec.path == null then
      throw "euvlok host ${name} must define either `configuration` or `path`."
    else
      let
        imported = import spec.path inputs;
      in
      if spec.output == null then imported else imported.${spec.output};

  nixosConfigurations = mapAttrs mkHost (mergeUsers "nixosHosts");
  darwinConfigurations = mapAttrs mkHost (mergeUsers "darwinHosts");

in
{
  options.euvlok.users = mkOption {
    type = types.attrsOf userType;
    default = { };
    description = "Contributor-owned host and home configuration registry.";
  };

  config = {
    flake = {
      inherit nixosConfigurations darwinConfigurations;
      homeConfigurations = mergeUsers "homeConfigurations";
    };

    perSystem =
      { pkgs, system, ... }:
      let
        mkEvalCheck =
          kind: name: value:
          nameValuePair "eval-${kind}-${name}" (
            pkgs.runCommand "eval-${kind}-${name}" { } ''
              mkdir "$out"
              printf '%s\n' ${lib.strings.escapeShellArg (builtins.unsafeDiscardStringContext (toString value))} > "$out/drv-path"
            ''
          );
      in
      {
        checks = lib.attrsets.optionalAttrs (system == "x86_64-linux") (
          mapAttrs' (
            name: value: mkEvalCheck "nixos" name value.config.system.build.toplevel.drvPath
          ) nixosConfigurations
          // mapAttrs' (name: value: mkEvalCheck "darwin" name value.system.drvPath) darwinConfigurations
        );
      };
  };
}
