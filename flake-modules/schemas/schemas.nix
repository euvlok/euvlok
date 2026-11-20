{ inputs, lib, ... }:
let
  /**
    Describe an attribute-set output whose children all share a kind and
    validation predicate

    # Inputs

    `doc`
    : Description of the output

    `what`
    : Kind shown for each child in the inventory

    `check`
    : Predicate evaluated against each child value

    # Type

    ```
    mkValueSchema :: String -> String -> (Any -> Bool) -> FlakeSchema
    ```

    # Examples
    :::{.example}
    ## Inventory a string output

    ```nix
    (mkValueSchema "Labels" "label" lib.strings.isString).inventory { foo = "bar"; }
    => { children.foo = { what = "label"; evalChecks.isValid = true; }; }
    ```

    :::
  */
  mkValueSchema = doc: what: check: {
    version = 1;
    inherit doc;
    inventory = output: {
      children = lib.attrsets.mapAttrs (_: value: {
        inherit what;
        evalChecks.isValid = check value;
      }) output;
    };
  };

  /**
    Recognize a host inventory record without forcing host configurations

    # Inputs

    `host`
    : A candidate value, which may be missing host fields

    # Type

    ```
    isHost :: Any -> Bool
    ```

    # Examples
    :::{.example}
    ## Reject incomplete metadata

    ```nix
    isHost { class = "nixos"; }
    => false
    ```

    :::
  */
  isHost =
    host:
    lib.attrsets.isAttrs host
    && lib.lists.elem (host.class or null) [
      "darwin"
      "nixos"
    ]
    && lib.strings.isString (host.name or null)
    && lib.strings.isString (host.owner or null)
    && lib.strings.isString (host.runner or null)
    && lib.strings.isString (host.system or null);

  /**
    Inventory named derivation paths without instantiating new derivations

    # Inputs

    `paths`
    : Attribute set mapping each child name to its derivation path

    # Type

    ```
    pathChildren :: AttrSet -> AttrSet
    ```

    # Examples
    :::{.example}
    ## Inventory no derivation paths

    ```nix
    pathChildren { }
    => { }
    ```

    :::
  */
  pathChildren = lib.attrsets.mapAttrs (
    _: path: {
      what = "derivation path";
      evalChecks.isDerivationPath = lib.strings.isString path;
    }
  );

  pathSchema = {
    version = 1;
    doc = "Host derivation paths used for change detection.";
    inventory = paths: { children = pathChildren paths; };
  };
  pathsBySystemSchema = {
    version = 1;
    doc = "Derivation paths grouped by native Nix system.";
    inventory = output: {
      children = lib.attrsets.mapAttrs (system: paths: {
        forSystems = [ system ];
        children = pathChildren paths;
      }) output;
    };
  };
  buildsSchema = {
    version = 1;
    doc = "NixOS system derivations.";
    inventory = output: {
      children = lib.attrsets.mapAttrs (_: build: {
        what = "NixOS build";
        derivationAttrPath = [ ];
        forSystems = [ build.system ];
        evalChecks.isDerivation = build.type == "derivation";
      }) output;
    };
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
      flakeModules =
        mkValueSchema "Importable flake-parts modules." "flake-parts module"
          lib.types.deferredModule.check;
      hostChecks = pathSchema;
      hostChecksBySystem = pathsBySystemSchema;
      hostMetadata = mkValueSchema "Typed host inventory." "host metadata" isHost;
      lib = mkValueSchema "Reusable euvlok library values." "library value" (
        value: lib.attrsets.isAttrs value || lib.trivial.isFunction value || lib.lists.isList value
      );
      nixosBuilds = buildsSchema;
    };
  };
}
