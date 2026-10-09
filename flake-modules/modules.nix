{ inputs }:
{
  config,
  lib,
  ...
}:
let
  applyEuvlokInputsWith =
    module: args: lib.modules.importApply module ({ euvlokInputs = inputs; } // args);
  applyEuvlokInputs = module: applyEuvlokInputsWith module { };

  mkDesktopModule = module: {
    imports = [
      ../modules/nixos/services.nix
      module
    ];
  };

  moduleCatalogs = {
    nixos = import ./modules/nixos.nix {
      inherit applyEuvlokInputs mkDesktopModule;
    };
    darwin = import ./modules/darwin.nix {
      inherit applyEuvlokInputs;
      euvlokInputs = inputs;
    };
    homeManager = import ./modules/home-manager.nix {
      inherit applyEuvlokInputs applyEuvlokInputsWith;
    };
  };
in
{
  config.flake = {
    # flake.modules owns the class/location wrappers and merges additions
    # made by downstream flake modules
    modules = moduleCatalogs;

    # Conventional aliases reuse the merged catalogs for consumers and hosts
    nixosModules = config.flake.modules.nixos;
    darwinModules = config.flake.modules.darwin;
    homeModules = config.flake.modules.homeManager;
  };
}
