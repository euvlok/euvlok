{
  euvlokInputs,
  isDarwin,
}:
{
  config,
  lib,
  ...
}:
let
  registry = lib.attrsets.mapAttrs (
    _: flake: lib.modules.mkDefault { inherit flake; }
  ) config.euvlok.nix.registryInputs;
  nixPathEntries = [ "nixpkgs=flake:nixpkgs" ];
in
{

  options.euvlok.nix.registryInputs = lib.options.mkOption {
    type = lib.types.attrsOf (lib.types.addCheck lib.types.raw (lib.types.isType "flake"));
    default = {
      inherit (euvlokInputs) nixpkgs;
    };
    description = "Locked flake inputs exposed through the system Nix registry.";
  };

  config = lib.modules.mkMerge [
    {
      assertions = [
        {
          assertion = config.euvlok.nix.registryInputs ? nixpkgs;
          message = "euvlok.nix.registryInputs must contain nixpkgs for NIX_PATH.";
        }
      ];
    }
    (
      if isDarwin then
        {
          environment.files."nix/registry.json".text = builtins.toJSON {
            version = 2;
            flakes = lib.attrsets.mapAttrsToList (name: flake: {
              from = {
                type = "indirect";
                id = name;
              };
              to = {
                type = "path";
                path = flake.outPath;
              }
              // lib.attrsets.filterAttrs (
                key: _:
                builtins.elem key [
                  "lastModified"
                  "rev"
                  "revCount"
                  "narHash"
                ]
              ) flake;
              exact = true;
            }) config.euvlok.nix.registryInputs;
          };
          # Nixd owns nix-path, so shell lookups use the session environment
          environment.variables.NIX_PATH = lib.strings.concatStringsSep ":" nixPathEntries;
          determinateNix.customSettings.flake-registry = "/etc/nix/registry.json";
        }
      else
        {
          nix = {
            # Lock only the explicitly selected inputs while preserving
            # unrelated host registry entries.
            inherit registry;
            settings.nix-path = nixPathEntries;
          };
        }
    )
  ];
}
