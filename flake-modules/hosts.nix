{
  providerInputs,
  supportedSystems,
}:
{
  config,
  lib,
  flake-parts-lib,
  ...
}:
let
  hostType = lib.types.submodule (
    { name, ... }:
    {
      options = {
        owner = lib.options.mkOption {
          type = lib.types.nonEmptyStr;
          description = "Contributor responsible for ${name}.";
        };

        class = lib.options.mkOption {
          type = lib.types.enum [
            "nixos"
            "darwin"
          ];
          description = "Module class and configuration output used by ${name}.";
        };

        system = lib.options.mkOption {
          type = lib.types.enum supportedSystems;
          description = "Nix platform evaluated for ${name}.";
        };

        runner = lib.options.mkOption {
          type = lib.types.nonEmptyStr;
          description = "Native GitHub Actions runner used to build ${name}.";
        };

        modules = lib.options.mkOption {
          type = lib.types.listOf lib.types.deferredModule;
          description = "Complete module graph for ${name}.";
        };

        builder = lib.options.mkOption {
          type = lib.types.nullOr (lib.types.functionTo lib.types.raw);
          default = null;
          description = "Optional replacement for nixosSystem/darwinSystem.";
        };
      };
    }
  );

  hostSpecs = config.euvlok.hosts;
  nixosSpecs = lib.attrsets.filterAttrs (_: host: host.class == "nixos") hostSpecs;
  darwinSpecs = lib.attrsets.filterAttrs (_: host: host.class == "darwin") hostSpecs;

  mkConfiguration =
    name: host:
    let
      builder =
        if host.builder != null then
          host.builder
        else if host.class == "nixos" then
          providerInputs.nixpkgs.lib.nixosSystem
        else
          providerInputs.nix-darwin.lib.darwinSystem;

      configuration = builder {
        modules = host.modules ++ [
          {
            _file = "${toString ./hosts.nix}#euvlok.hosts.${name}.system";
            nixpkgs.hostPlatform = lib.modules.mkDefault host.system;
          }
        ];
      };

      actualSystem = configuration.pkgs.stdenv.hostPlatform.system;
    in
    if actualSystem == host.system then
      configuration
    else
      throw "euvlok host ${name} declares ${host.system} but evaluates with ${actualSystem}";

  nixosConfigurations = lib.attrsets.mapAttrs mkConfiguration nixosSpecs;
  darwinConfigurations = lib.attrsets.mapAttrs mkConfiguration darwinSpecs;

  # Determinate Nix can evaluate independent values on its evaluator worker
  # pool. Start the expensive system, Home Manager package, and activation
  # branches in parallel, then return the conventional toplevel derivation.
  mkNixosBuild =
    _: host:
    let
      cfg = host.config;
      homeUsers = lib.attrsets.attrByPath [ "home-manager" "users" ] { } cfg;
      work = [
        cfg.system.path.drvPath
      ]
      ++ lib.attrsets.mapAttrsToList (_: user: user.home.path.drvPath) homeUsers
      ++ lib.attrsets.mapAttrsToList (_: user: user.home.activationPackage.drvPath) homeUsers;
    in
    builtins.parallel work cfg.system.build.toplevel;

  nixosBuilds = lib.attrsets.mapAttrs mkNixosBuild nixosConfigurations;

  hostMetadata = lib.attrsets.mapAttrs (name: host: {
    inherit name;
    inherit (host)
      class
      owner
      runner
      system
      ;
  }) hostSpecs;

  hostChecks =
    lib.attrsets.mapAttrs (_: build: build.drvPath) nixosBuilds
    // lib.attrsets.mapAttrs (_: host: host.system.drvPath) darwinConfigurations;
in
{
  imports = [
    (flake-parts-lib.mkTransposedPerSystemModule {
      name = "hostChecksBySystem";
      file = ./hosts.nix;
      option = lib.options.mkOption {
        type = lib.types.lazyAttrsOf lib.types.str;
        default = { };
        description = "Native host derivation paths used for CI change detection.";
      };
    })
  ];

  options.euvlok.hosts = lib.options.mkOption {
    type = lib.types.attrsOf hostType;
    default = { };
    description = "Typed inventory of all NixOS and nix-darwin machines.";
  };

  config.perSystem = { system, ... }: {
    hostChecksBySystem = lib.attrsets.filterAttrs (
      name: _: hostSpecs.${name}.system == system
    ) hostChecks;
  };

  config.flake = {
    inherit
      darwinConfigurations
      hostChecks
      hostMetadata
      nixosBuilds
      nixosConfigurations
      ;
  };
}
