{ inputs, lib, ... }:
let
  mkChildren = children: { inherit children; };
  mkValueSchema = doc: what: check: {
    version = 1;
    inherit doc;
    inventory =
      output:
      mkChildren (
        lib.attrsets.mapAttrs (_: value: {
          inherit what;
          evalChecks.isValid = check value;
        }) output
      );
  };

  isModule = lib.types.deferredModule.check;
  isHost =
    host:
    lib.attrsets.isAttrs host
    && lib.strings.isString host.class
    && lib.lists.elem host.class [
      "darwin"
      "nixos"
    ]
    && lib.strings.isString host.name
    && lib.strings.isString host.owner
    && lib.strings.isString host.runner
    && lib.strings.isString host.system;
  isLibraryValue =
    value: lib.attrsets.isAttrs value || lib.trivial.isFunction value || lib.lists.isList value;

  pathSchema = doc: {
    version = 1;
    inherit doc;
    inventory =
      output:
      mkChildren (
        lib.attrsets.mapAttrs (_: path: {
          what = "derivation path";
          evalChecks.isDerivationPath = lib.strings.isString path;
        }) output
      );
  };
  pathsBySystemSchema = {
    version = 1;
    doc = "Derivation paths grouped by native Nix system.";
    inventory =
      output:
      mkChildren (
        lib.attrsets.mapAttrs (system: paths: {
          forSystems = [ system ];
          children = lib.attrsets.mapAttrs (_: path: {
            what = "derivation path";
            evalChecks.isDerivationPath = lib.strings.isString path;
          }) paths;
        }) output
      );
  };
  buildsSchema = {
    version = 1;
    doc = "NixOS system derivations.";
    inventory =
      output:
      mkChildren (
        lib.attrsets.mapAttrs (_: build: {
          what = "NixOS build";
          derivationAttrPath = [ ];
          forSystems = [ build.system ];
          evalChecks.isDerivation = build.type == "derivation";
        }) output
      );
  };
in
{
  options.flake.schemas = lib.options.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = { };
    description = "Flake output schemas, indexed by output name";
  };

  config.flake = {
    schemas = inputs.flake-schemas.schemas // {
      flakeModules = mkValueSchema "Importable flake-parts modules." "flake-parts module" isModule;
      hostChecks = pathSchema "Host derivation paths used for change detection.";
      hostChecksBySystem = pathsBySystemSchema;
      hostMetadata = mkValueSchema "Typed host inventory." "host metadata" isHost;
      lib = mkValueSchema "Reusable euvlok library values." "library value" isLibraryValue;
      nixosBuilds = buildsSchema;
    };
  };
}
