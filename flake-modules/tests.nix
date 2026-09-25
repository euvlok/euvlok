{ providerInputs }:
{
  config,
  lib,
  ...
}:
let
  linuxSystem = "x86_64-linux";
  darwinSystem = "aarch64-darwin";
  pkgs = import providerInputs.nixpkgs { system = linuxSystem; };

  nixosConsumer = providerInputs.nixpkgs.lib.nixosSystem {
    modules = [
      config.flake.nixosModules.default
      {
        nixpkgs.hostPlatform = linuxSystem;
        boot.loader.grub.devices = [ "nodev" ];
        fileSystems."/" = {
          device = "none";
          fsType = "tmpfs";
        };
        system.stateVersion = "26.11";
      }
    ];
  };

  darwinConsumer = providerInputs.nix-darwin.lib.darwinSystem {
    modules = [
      config.flake.darwinModules.default
      {
        nixpkgs.hostPlatform = darwinSystem;
        system.primaryUser = "consumer";
        system.stateVersion = 7;
        users.users.consumer.home = "/Users/consumer";
      }
    ];
  };

  standaloneHome = providerInputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      config.flake.homeModules.default
      {
        home = {
          username = "consumer";
          homeDirectory = "/home/consumer";
          stateVersion = "26.11";
        };
        euvlok.home = {
          languages.rust.enable = true;
          vscode.enable = true;
        };
      }
    ];
  };

  serverHome = providerInputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      config.flake.homeModules.nixpkgs
      config.flake.homeModules.server
      {
        home = {
          username = "consumer";
          homeDirectory = "/home/consumer";
          stateVersion = "26.11";
        };
        programs.fastfetch.enable = true;
        programs.nh.enable = true;
        euvlok.home = {
          helix.enable = true;
          yazi.enable = true;
        };
      }
    ];
  };

  integratedNixos = providerInputs.nixpkgs.lib.nixosSystem {
    modules = [
      config.flake.nixosModules.default
      providerInputs.home-manager.nixosModules.home-manager
      {
        nixpkgs.hostPlatform = linuxSystem;
        nixpkgs.overlays = [
          (_: _: { euvlokPkgsIdentity = true; })
        ];
        system.stateVersion = "26.11";
        users.users.consumer = {
          isNormalUser = true;
          home = "/home/consumer";
        };
        home-manager = {
          useGlobalPkgs = true;
          sharedModules = [ config.flake.homeModules.integrated ];
          users.consumer =
            { pkgs, ... }:
            {
              assertions = [
                {
                  assertion = pkgs.euvlokPkgsIdentity;
                  message = "integrated Home Manager must use the parent system pkgs";
                }
              ];
              home = {
                username = "consumer";
                homeDirectory = "/home/consumer";
                stateVersion = "26.11";
              };
            };
        };
      }
    ];
  };

  nvidiaGuiConsumer = providerInputs.nixpkgs.lib.nixosSystem {
    modules = [
      config.flake.nixosModules.default
      {
        nixpkgs.hostPlatform = linuxSystem;
        system.stateVersion = "26.11";
        euvlok.nixos = {
          gui.enable = true;
          nvidia.enable = true;
        };
      }
    ];
  };

  hasDesktopPackages = lib.lists.any (
    package: lib.strings.getName package == "pavucontrol"
  ) nvidiaGuiConsumer.config.environment.systemPackages;

  hasLldb = lib.lists.any (
    extension: lib.strings.hasInfix "vscode-lldb" (lib.strings.getName extension)
  ) standaloneHome.config.programs.vscode.profiles.default.extensions;

  results =
    assert hasDesktopPackages;
    assert hasLldb;
    assert !(serverHome.config.euvlok.home ? languages);
    assert !(serverHome.config.euvlok.home ? vscode);
    assert !serverHome.config.programs.ghostty.enable;
    assert !serverHome.config.programs.vscode.enable;
    {
      darwinSystem = darwinConsumer.system.drvPath;
      integratedHome = integratedNixos.config.home-manager.users.consumer.home.activationPackage.drvPath;
      nixosSystem = nixosConsumer.config.system.build.toplevel.drvPath;
      serverHome = serverHome.activationPackage.drvPath;
      standaloneHome = standaloneHome.activationPackage.drvPath;
    };
in
{

  perSystem =
    { system, ... }:
    lib.attrsets.optionalAttrs (system == linuxSystem) {
      checks.module-consumers =
        pkgs.runCommand "euvlok-module-consumers"
          {
            payload = builtins.unsafeDiscardStringContext (builtins.toJSON results);
          }
          ''
            mkdir -p "$out"
            printf '%s\n' "$payload" > "$out/results.json"
          '';
    };
}
