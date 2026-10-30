{
  config,
  inputs,
  lib,
  partitionStack,
  ...
}:
let
  # Keep this list explicit: these are the systems with contributor hosts or
  # development support in this repository
  supportedSystems = [
    "aarch64-darwin"
    "aarch64-linux"
    "x86_64-linux"
  ];

  packagesModule = lib.modules.importApply ./packages.nix { providerInputs = inputs; };

  # Capture provider-owned inputs in the published module so consumers can
  # import it without recreating euvlok's input names or loading its
  # flake-parts extensions themselves
  euvlokModule = {
    imports = [
      inputs.flake-parts.flakeModules.modules
      inputs.home-manager.flakeModules.default
      inputs.nix-darwin.flakeModules.default
      (lib.modules.importApply ./hosts.nix {
        providerInputs = inputs;
        inherit supportedSystems;
      })
      (lib.modules.importApply ./modules.nix { inherit inputs; })
      (lib.modules.importApply ./overlays.nix { inherit inputs supportedSystems; })
      packagesModule
    ];
  };
in
{
  imports = [
    inputs.flake-parts.flakeModules.flakeModules
    inputs.flake-parts.flakeModules.partitions
    inputs.flake-parts.flakeModules.touchup
    euvlokModule
    ./schemas/schemas.nix
  ];

  systems = supportedSystems;

  perSystem =
    { pkgs, system, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      formatter = pkgs.nixfmt-tree;

      # Keep the established generator installables lazy for package consumers
      packages = lib.attrsets.optionalAttrs (partitionStack == [ ]) (
        lib.attrsets.genAttrs [ "write-flake" "write-inputs" "write-lock" ] (
          name: config.partitions.dev.module.allSystems.${system}.packages.${name}
        )
      );
    };

  # Keep contributor-owned inputs out of the main entry path. Host outputs
  # and their evaluation checks opt into those inputs
  partitionedAttrs = {
    checks = "dev";
    darwinConfigurations = "users";
    hostChecks = "users";
    hostChecksBySystem = "users";
    hostMetadata = "users";
    nixosBuilds = "users";
    nixosConfigurations = "users";
  };

  partitions = {
    dev.module.imports = [
      ./inputs
      (lib.modules.importApply ./tests.nix { providerInputs = inputs; })
    ];

    users = {
      extraInputsFlake = ./users;
      module.imports = [ ./users/default.nix ];
    };
  };

  # `flake.modules` is the typed source of truth. The conventional
  # nixosModules/darwinModules/homeModules aliases are the public interface
  touchup.attr = {
    flakeModule.enable = false;
    homeConfigurations.enable = false;
    modules.enable = false;
  };

  flake = {
    flakeModules = {
      default = euvlokModule;
      packages = packagesModule;
    };
  };
}
