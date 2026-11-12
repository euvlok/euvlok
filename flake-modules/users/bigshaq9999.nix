{
  config,
  inputs,
  lib,
  ...
}:
{

  euvlok.hosts.faputa = {
    owner = "bigshaq9999";
    class = "darwin";
    system = "aarch64-darwin";
    runner = "macos-latest";
    modules = [
      (lib.modules.importApply ../../hosts/darwin/bigshaq9999/faputa {
        sharedModules = [
          config.flake.darwinModules.default
          config.flake.darwinModules.zsh
        ];
        homeModule = lib.modules.importApply ../../hosts/darwin/bigshaq9999/faputa/home.nix {
          homeManagerModule = inputs.home-manager.darwinModules.home-manager;
          personalModule = ../../hosts/hm/bigshaq9999;
          raycastModule = inputs.raycast.homeManagerModules.default;
          raycastPackage = inputs.raycast.packages.aarch64-darwin.raycast;
          sharedModule = config.flake.homeModules.integrated;
        };
      })
    ];
  };

  euvlok.hosts.nanachi = {
    owner = "bigshaq9999";
    class = "nixos";
    system = "x86_64-linux";
    runner = "ubuntu-26.04";
    modules = [
      (lib.modules.importApply ../../hosts/linux/bigshaq9999/nanachi {
        sharedModule = config.flake.nixosModules.default;
        homeModule = lib.modules.importApply ../../hosts/linux/bigshaq9999/nanachi/home.nix {
          homeManagerModule = inputs.home-manager.nixosModules.home-manager;
          personalModule = ../../hosts/hm/bigshaq9999;
          sharedModule = config.flake.homeModules.integrated;
        };
      })
    ];
  };
}
