{
  inputs,
  lib,
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
    ./inputs
    ./schemas/schemas.nix
    (lib.modules.importApply ./tests.nix { providerInputs = inputs; })
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
    };

  # Keep contributor-owned inputs out of the main entry path. Host outputs
  # and their evaluation checks opt into those inputs
  partitionedAttrs = {
    darwinConfigurations = "users";
    hostChecks = "users";
    hostChecksBySystem = "users";
    hostMetadata = "users";
    nixosBuilds = "users";
    nixosConfigurations = "users";
  };

  partitions = {
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
