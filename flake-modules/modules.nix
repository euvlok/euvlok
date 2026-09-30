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
    # Feed raw modules to each output. flake-parts, Home Manager, and the
    # flake.modules extension add their own source/class wrapper where needed.
    modules = moduleCatalogs;

    # Conventional aliases for external consumers and internal hosts/**/*.nix.
    nixosModules = moduleCatalogs.nixos;
    # nix-darwin does not declare a typed `darwinModules` flake-parts option.
    # Reuse the class/location wrapper from `flake.modules` for this conventional
    # alias instead of publishing the raw catalog.
    darwinModules = config.flake.modules.darwin;
    homeModules = moduleCatalogs.homeManager;
  };
}
