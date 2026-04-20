{ config, lib, ... }:
{
  # nix-darwin has no flake-parts module, so the `flake.darwinConfigurations`
  # output would otherwise land on the freeform merger that refuses multiple
  # definitions. Declaring it as a lazyAttrsOf lets user modules each
  # contribute their hosts the same way `nixosConfigurations` works.
  options.flake.darwinConfigurations = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = { };
  };

  config.flake = {
    modules = {
      nixos.default = import ../modules/nixos;
      darwin.default = ../modules/darwin;
      homeManager.default = ../modules/hm;
      homeManager.os = ../modules/hm/os;
    };

    # Legacy aliases for external consumers and internal hosts/**/*.nix
    nixosModules.default = config.flake.modules.nixos.default;
    darwinModules.default = config.flake.modules.darwin.default;
    homeModules = {
      inherit (config.flake.modules.homeManager) default os;
    };
  };
}
