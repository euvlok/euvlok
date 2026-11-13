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
  tenjinCaModule = ../../hosts/shared/tenjin-ca.nix;
  catppuccinModule = lib.modules.importApply ../../hosts/hm/ashuramaruzxc/catppuccin.nix {
    catppuccinGtkModule = config.flake.homeModules.catppuccin-gtk;
  };
  jetbrainsModule = {
    nixpkgs.overlays = [
      (import ../../hosts/hm/ashuramaruzxc/jetbrains.nix {
        jetbrainsPlugins = inputs.nix-jetbrains-plugins;
      })
    ];
  };

  aiToolsModule = {
    nixpkgs.overlays = [
      (final: _: {
        aiTools =
          let
            # Use 4evy/ai's pinned runtime and patched omp
            packages = inputs.ai.packages.${final.stdenv.hostPlatform.system};
          in
          packages
          // {
            # Keep the existing Codex and Claude launchers in the profile
            ai-tools = lib.meta.lowPrio packages.ai-tools;
          };
      })
    ];
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
        animeCursorsPackage =
          pkgs:
          let
            cursorPackages =
              (pkgs.callPackage "${inputs.anime-cursors-source}/pkgs" {
                cursorgenSrc = inputs.cursorgen-source;
              }).overrideScope
                (
                  final: _: {
                    cursorgen = pkgs.python314Packages.callPackage "${inputs.cursorgen-source}/pkgs/cursorgen.nix" { };
                    # Scope the newer dependencies to the converter
                    converter =
                      (pkgs.python314Packages.callPackage "${inputs.anime-cursors-source}/pkgs/converter.nix" {
                        inherit (final) cursorgen;
                        inherit (final.pythonPackages) msgspec platformdirs;
                      }).overridePythonAttrs
                        (old: {
                          # Allow Nixpkgs' uv-build 0.13 until upstream widens its bound:
                          # https://github.com/4evy/anime-cursors/blob/72e37ac5ad2fd2b2098353603467155f75c8e362/pyproject.toml
                          postPatch = (old.postPatch or "") + ''
                            substituteInPlace pyproject.toml \
                              --replace-fail 'uv_build>=0.11.28,<0.13' 'uv_build>=0.11.28,<0.14'
                          '';
                        });
                  }
                );
          in
          (cursorPackages.cursors.override { themes = [ "hakurei-reimu" ]; }).variants.hakurei-reimu;
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
        tenjinCaModule
        jetbrainsModule
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
      runner = "ubuntu-26.04";
      modules = [
        tenjinCaModule
        jetbrainsModule
        aiToolsModule
        (lib.modules.importApply ../../hosts/linux/ashuramaruzxc/unsigned-int32 {
          sharedModule = sharedNixosModule;
          homeModule =
            mkHomeModule ../../hosts/linux/ashuramaruzxc/unsigned-int32/home.nix
              inputs.home-manager.nixosModules.home-manager
              {
                aiModule = inputs.ai.homeManagerModules.default;
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
      runner = "ubuntu-26.04";
      modules = [
        tenjinCaModule
        (lib.modules.importApply ../../hosts/linux/ashuramaruzxc/unsigned-int64 {
          sharedModule = sharedNixosModule;
          ecolinkerModule =
            { pkgs, ... }:
            {
              imports = [ inputs.ecolinker.nixosModules.default ];
              # Upstream's vendorHash predates its October dependency updates.
              services.ecolinker.package =
                inputs.ecolinker.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs
                  {
                    vendorHash = "sha256-lu28fn/1k8MDrsHTlg9zme1fd/kB1awlykIYGoOZzF8=";
                  };
            };
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
        tenjinCaModule
        jetbrainsModule
        aiToolsModule
        (lib.modules.importApply ../../hosts/darwin/ashuramaruzxc/unsigned-int8 {
          containerPackage = inputs.nixpkgs.legacyPackages.aarch64-darwin.container;
          sharedModules = [
            config.flake.darwinModules.default
            config.flake.darwinModules.zsh
          ];
          homeModule = lib.modules.importApply ../../hosts/darwin/ashuramaruzxc/unsigned-int8/home.nix {
            inherit personalModule;
            aiModule = inputs.ai.homeManagerModules.default;
            homeManagerModule = inputs.home-manager.darwinModules.home-manager;
            raycastModule = inputs.raycast.homeManagerModules.default;
            raycastPackage = inputs.raycast.packages.aarch64-darwin.raycast;
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
