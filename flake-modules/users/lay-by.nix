{
  config,
  inputs,
  lib,
  ...
}:
let
  zenBrowserPackage = inputs.zen-browser.packages.x86_64-linux.default;
in
{

  euvlok.hosts.blind-faith = {
    owner = "lay-by";
    class = "nixos";
    system = "x86_64-linux";
    runner = "ubuntu-26.04";
    modules = [
      (lib.modules.importApply ../../hosts/linux/lay-by/blind-faith {
        sharedModule = config.flake.nixosModules.default;
        stylixModule = inputs.stylix.nixosModules.stylix;
        unstableSource = inputs.nixpkgs-unstable;
        configurationModule =
          lib.modules.importApply ../../hosts/linux/lay-by/blind-faith/configuration.nix
            {
              inherit zenBrowserPackage;
            };
        homeModule = lib.modules.importApply ../../hosts/linux/lay-by/blind-faith/home.nix {
          inherit zenBrowserPackage;
          homeManagerModule = inputs.home-manager.nixosModules.home-manager;
          personalModule = ../../hosts/hm/lay-by;
          sharedModule = config.flake.homeModules.integrated;
          spicetify = inputs.spicetify-nix;
        };
      })
    ];
  };

  euvlok.hosts.nyx = {
    owner = "lay-by";
    class = "nixos";
    system = "x86_64-linux";
    runner = "ubuntu-26.04";
    modules = [
      (lib.modules.importApply ../../hosts/linux/lay-by/nyx {
        sharedModule = config.flake.nixosModules.default;
        stylixModule = inputs.stylix.nixosModules.stylix;
        unstableSource = inputs.nixpkgs-unstable;
        configurationModule = lib.modules.importApply ../../hosts/linux/lay-by/nyx/configuration.nix {
          inherit zenBrowserPackage;
        };
        homeModule = lib.modules.importApply ../../hosts/linux/lay-by/nyx/home.nix {
          inherit zenBrowserPackage;
          homeManagerModule = inputs.home-manager.nixosModules.home-manager;
          personalModule = ../../hosts/hm/lay-by/nyx;
          sharedModule = config.flake.homeModules.integrated;
          spicetify = inputs.spicetify-nix;
        };
      })
    ];
  };
}
