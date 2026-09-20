{
  config,
  inputs,
  lib,
  ...
}:
let
  personalModule = ../../hosts/hm/ashuramaruzxc;
  sharedHomeModule = config.flake.homeModules.integrated;
  sharedNixosModule = config.flake.nixosModules.default;
  catppuccinModule = lib.modules.importApply ../../hosts/hm/ashuramaruzxc/catppuccin.nix {
    catppuccinGtkModule = config.flake.homeModules.catppuccin-gtk;
  };

  mkHomeModule =
    path: homeManagerModule: extraArgs:
    lib.modules.importApply path (
      {
        inherit
          catppuccinModule
          homeManagerModule
          personalModule
          ;
        animeCursorsSource = inputs.anime-cursors-source;
        sharedModule = sharedHomeModule;
      }
      // extraArgs
    );
in
{

  euvlok.hosts = {
    unsigned-int16 = {
      owner = "ashuramaruzxc";
      class = "nixos";
      system = "aarch64-linux";
      runner = "ubuntu-24.04-arm";
      builder = inputs.nixos-raspberrypi.lib.nixosSystem;
      modules = [
        (lib.modules.importApply ../../hosts/linux/ashuramaruzxc/unsigned-int16 {
          sharedModule = sharedNixosModule;
          homeModule =
            mkHomeModule ../../hosts/linux/ashuramaruzxc/unsigned-int16/home.nix
              inputs.home-manager.nixosModules.home-manager
              { };
          diskoModule = inputs.disko-rpi.nixosModules.disko;
          flatpakModule = inputs.flatpak-declarative.nixosModules.default;
          raspberryPiModules = [
            inputs.nixos-raspberrypi.nixosModules.usb-gadget-ethernet
            inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.base
            inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.bluetooth
            inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.display-vc4
            inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.page-size-16k
          ];
        })
      ];
    };

    unsigned-int32 = {
      owner = "ashuramaruzxc";
      class = "nixos";
      system = "x86_64-linux";
      runner = "ubuntu-latest";
      modules = [
        (lib.modules.importApply ../../hosts/linux/ashuramaruzxc/unsigned-int32 {
          sharedModule = sharedNixosModule;
          homeModule =
            mkHomeModule ../../hosts/linux/ashuramaruzxc/unsigned-int32/home.nix
              inputs.home-manager.nixosModules.home-manager
              {
                codexDesktopModule = inputs.codex-desktop-linux.homeManagerModules.default;
              };
          flatpakModule = inputs.flatpak-declarative.nixosModules.default;
        })
      ];
    };

    unsigned-int64 = {
      owner = "ashuramaruzxc";
      class = "nixos";
      system = "x86_64-linux";
      runner = "ubuntu-latest";
      modules = [
        (lib.modules.importApply ../../hosts/linux/ashuramaruzxc/unsigned-int64 {
          sharedModule = sharedNixosModule;
          homeModule = lib.modules.importApply ../../hosts/linux/ashuramaruzxc/unsigned-int64/home.nix {
            inherit
              catppuccinModule
              personalModule
              ;
            coreModule = config.flake.homeModules.core;
            homeManagerModule = inputs.home-manager.nixosModules.home-manager;
            serverModule = config.flake.homeModules.server;
            serverPersonalModule = ../../hosts/hm/ashuramaruzxc/server.nix;
            sharedModule = sharedHomeModule;
          };
        })
      ];
    };

    unsigned-int8 = {
      owner = "ashuramaruzxc";
      class = "darwin";
      system = "aarch64-darwin";
      runner = "macos-latest";
      modules = [
        (lib.modules.importApply ../../hosts/darwin/ashuramaruzxc/unsigned-int8 {
          sharedModules = [
            config.flake.darwinModules.default
            config.flake.darwinModules.zsh
          ];
          homeModule = lib.modules.importApply ../../hosts/darwin/ashuramaruzxc/unsigned-int8/home.nix {
            inherit personalModule;
            homeManagerModule = inputs.home-manager.darwinModules.home-manager;
            sharedModule = sharedHomeModule;
          };
          homebrewModule = inputs.nix-homebrew.darwinModules.nix-homebrew;
          homebrewTaps = {
            "homebrew/homebrew-core" = inputs.homebrew-core-source;
            "homebrew/homebrew-cask" = inputs.homebrew-cask-source;
            "cfergeau/homebrew-crc" = inputs.homebrew-crc-source;
          };
        })
      ];
    };
  };
}
