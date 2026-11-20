{ inputs }:
{
  config,
  lib,
  ...
}:
let
  /**
    Partially apply a repository module with provider inputs and any extra
    arguments before adding it to a module catalog

    # Inputs

    `module`
    : Module file with an outer argument set

    `args`
    : Extra outer arguments, which can override `euvlokInputs`

    # Type

    ```
    applyEuvlokInputsWith :: Path -> AttrSet -> Module
    ```

    # Examples
    :::{.example}
    ## Publish a module without extra arguments

    ```nix
    applyEuvlokInputsWith ../modules/darwin/sops.nix { }
    => a module with the provider inputs already applied
    ```

    :::
  */
  applyEuvlokInputsWith =
    module: args: lib.modules.importApply module ({ euvlokInputs = inputs; } // args);

  /**
    Partially apply a repository module with only the provider inputs

    # Inputs

    `module`
    : Module file with an outer `euvlokInputs` argument

    # Type

    ```
    applyEuvlokInputs :: Path -> Module
    ```

    # Examples
    :::{.example}
    ## Publish a module that takes only the provider inputs

    ```nix
    applyEuvlokInputs ../modules/darwin/sops.nix
    => applyEuvlokInputsWith ../modules/darwin/sops.nix { }
    ```

    :::
  */
  applyEuvlokInputs = module: applyEuvlokInputsWith module { };

  /**
    Include the shared services alongside a desktop-specific NixOS module

    # Inputs

    `module`
    : Desktop-specific NixOS module or path

    # Type

    ```
    mkDesktopModule :: Module -> Module
    ```

    # Examples
    :::{.example}
    ## Compose the GNOME module with shared services

    ```nix
    (mkDesktopModule ../modules/nixos/gnome.nix).imports
    => [ ../modules/nixos/services.nix ../modules/nixos/gnome.nix ]
    ```

    :::
  */
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
