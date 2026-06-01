{
  description = "EUVlok Communal Dotfiles";

  nixConfig = {
    extra-substituters = [ "https://catppuccin.cachix.org" ];
    extra-trusted-public-keys = [
      "catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732IysmU="
    ];
  };

  inputs = {
    # --- Shared ---
    eupkgs.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    eupkgs.url = "github:euvlok/pkgs";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    nixpkgs-unstable-small.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    nixpkgs-master.url = "github:NixOS/nixpkgs";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";

    # --- Trivial ---
    catppuccin-gtk.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    catppuccin-gtk.url = "github:catppuccin/nix/06f0ea19334bcc8112e6d671fd53e61f9e3ad63a";
    catppuccin-trivial.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    catppuccin-trivial.url = "github:catppuccin/nix";
    niri-flake-trivial.inputs.nixpkgs-stable.follows = "nixpkgs";
    niri-flake-trivial.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    niri-flake-trivial.url = "github:sodiboo/niri-flake";
    noctalia-trivial.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    noctalia-trivial.url = "github:noctalia-dev/noctalia-shell";
    nix-homebrew-trivial.url = "github:zhaofengli/nix-homebrew";
    nix4jetbrains-trivial.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    nix4jetbrains-trivial.url = "github:nix-community/nix-jetbrains-plugins";
    nix4vscode-trivial.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    nix4vscode-trivial.inputs.systems.follows = "flake-utils/systems";
    nix4vscode-trivial.url = "github:nix-community/nix4vscode";
    nixos-vscode-server-trivial.inputs.flake-utils.follows = "flake-utils-linux";
    nixos-vscode-server-trivial.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    nixos-vscode-server-trivial.url = "github:nix-community/nixos-vscode-server";
    nixcord-trivial.inputs.flake-compat.follows = "";
    nixcord-trivial.inputs.flake-parts.follows = "flake-parts";
    nixcord-trivial.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    nixcord-trivial.url = "github:FlameFlag/nixcord";
    nvidia-patch-trivial.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    nvidia-patch-trivial.inputs.utils.follows = "flake-utils";
    nvidia-patch-trivial.url = "github:icewind1991/nvidia-patch-nixos";
    sops-nix-trivial.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    sops-nix-trivial.url = "github:Mic92/sops-nix";
    stylix-trivial.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    stylix-trivial.inputs.systems.follows = "flake-utils/systems";
    stylix-trivial.url = "github:danth/stylix/release-25.11";
    zen-browser-trivial.inputs.home-manager.follows = "home-manager";
    zen-browser-trivial.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    zen-browser-trivial.url = "github:0xc000022070/zen-browser-flake";

    # Infra / Shared / Core Inputs
    devenv.inputs.cachix.inputs.flake-compat.follows = "";
    devenv.inputs.crate2nix.follows = "";
    devenv.inputs.flake-compat.follows = "";
    devenv.inputs.flake-parts.follows = "flake-parts";
    devenv.inputs.git-hooks.inputs.gitignore.follows = "";
    devenv.inputs.nixd.follows = "";
    devenv.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    devenv.url = "github:cachix/devenv";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-utils-linux.inputs.systems.follows = "linux-systems-trivial";
    flake-utils-linux.url = "github:numtide/flake-utils";
    flake-utils.url = "github:numtide/flake-utils"; # ONLY Exists to override inputs (NOT TO BE USED)
    linux-systems-trivial.url = "github:nix-systems/default-linux";
    pre-commit-hooks.inputs.flake-compat.follows = "";
    pre-commit-hooks.inputs.gitignore.follows = "";
    pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.flake-parts.flakeModules.easyOverlay
        inputs.flake-parts.flakeModules.flakeModules
        inputs.flake-parts.flakeModules.modules
        inputs.flake-parts.flakeModules.partitions
        inputs.flake-parts.flakeModules.touchup
        inputs.home-manager.flakeModules.default

        ./flake-modules/hosts.nix
        ./flake-modules/packages.nix
        ./flake-modules/modules.nix
      ];

      # Keep contributor-owned inputs out of the entry path. Host outputs
      # and host eval checks opt into the user input flake; devShells and
      # formatter only load the development tooling they need.
      partitionedAttrs = {
        darwinConfigurations = "users";
        devShells = "dev";
        checks = "checks";
        formatter = "dev";
        homeConfigurations = "users";
        nixosConfigurations = "users";
      };
      touchup.attr.modules.enable = false;

      partitions.users = {
        extraInputsFlake = ./flake-modules/users;
        module.imports = [
          ./flake-modules/hosts.nix
          ./flake-modules/modules.nix
          ./flake-modules/users/default.nix
        ];
      };

      partitions.checks = {
        extraInputsFlake = ./flake-modules/users;
        module.imports = [
          inputs.devenv.flakeModule
          inputs.pre-commit-hooks.flakeModule
          inputs.treefmt-nix.flakeModule
          ./flake-modules/hosts.nix
          ./flake-modules/modules.nix
          ./flake-modules/users/default.nix
          ./flake-modules/dev-shell.nix
        ];
      };

      partitions.dev.module.imports = [
        inputs.devenv.flakeModule
        inputs.pre-commit-hooks.flakeModule
        inputs.treefmt-nix.flakeModule
        ./flake-modules/dev-shell.nix
      ];

      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];

      flake.flakeModules.default = {
        imports = [
          ./flake-modules/hosts.nix
          ./flake-modules/modules.nix
          ./flake-modules/packages.nix
        ];
      };
    };
}
