{
  description = "EUVlok Communal Dotfiles";

  inputs = {
    # --- Shared ---
    eupkgs.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    eupkgs.url = "github:euvlok/pkgs";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    nixpkgs-unstable-small.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi";
    # This input is meant to be used for `-source` inputs and is rarely updated
    # to not cause constant rebuilds when updating generic unstable
    nixpkgs-source.url = "github:NixOS/nixpkgs/nixos-unstable";

    # --- Trivial ---
    base16-trivial.url = "github:SenchoPens/base16.nix";
    catppuccin-gtk.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    catppuccin-gtk.url = "github:catppuccin/nix/06f0ea19334bcc8112e6d671fd53e61f9e3ad63a";
    catppuccin-trivial.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    catppuccin-trivial.url = "github:catppuccin/nix/v25.11";
    flatpak-declerative-trivial.url = "github:in-a-dil-emma/declarative-flatpak";
    niri-flake-trivial.inputs.nixpkgs-stable.follows = "nixpkgs";
    niri-flake-trivial.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    niri-flake-trivial.url = "github:sodiboo/niri-flake";
    nix-homebrew-trivial.url = "github:zhaofengli/nix-homebrew";
    nix4vscode-trivial.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    nix4vscode-trivial.url = "github:nix-community/nix4vscode";
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
    spicetify-nix-trivial.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    spicetify-nix-trivial.url = "github:Gerg-L/spicetify-nix";
    stylix-trivial.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    stylix-trivial.url = "github:danth/stylix/release-25.11";
    zen-browser-trivial.inputs.home-manager.follows = "home-manager";
    zen-browser-trivial.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    zen-browser-trivial.url = "github:0xc000022070/zen-browser-flake";

    # ---- Source ----
    dis-source.inputs.nixpkgs.follows = "nixpkgs-source";
    dis-source.url = "github:FlameFlag/dis";

    # DO NOT OVERRIDE NIXPKGS
    anime-cursors-source.url = "github:ashuramaruzxc/anime-cursors";
    anime-cursors-source.inputs.flake-parts.follows = "flake-parts";
    anime-game-launcher-source.url = "github:ezKEa/aagl-gtk-on-nix";
    anime-game-launcher-source.inputs.flake-compat.follows = "";
    # DO NOT override stylix utilities inputs
    # stylix-trivial.inputs.flake-parts.follows = "";
    # stylix-trivial.inputs.git-hooks.follows = "pre-commit-hooks";
    # DO NOT override nixpkgs, it uses it's own fork

    # Infra / Shared / Core Inputs
    devenv.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    devenv.url = "github:cachix/devenv";
    disko-rpi.url = "github:nvmd/disko/gpt-attrs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-utils.url = "github:numtide/flake-utils"; # ONLY Exists to override inputs (NOT TO BE USED)
    mk-shell-bin.url = "github:rrbutani/nix-mk-shell-bin";
    nix2container.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    nix2container.url = "github:nlewo/nix2container";
    pre-commit-hooks.inputs.flake-compat.follows = "";
    pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";

    # Misc / Non Flakes sources(Trivial)
    homebrew-core-trivial = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask-trivial = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-crc-trivial = {
      url = "github:cfergeau/homebrew-crc";
      flake = false;
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.devenv.flakeModule ];
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      perSystem =
        { pkgs, system, ... }:
        {
          _module.args.pkgs = inputs.nixpkgs.legacyPackages.${system};
          checks = {
            pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
              src = ./.;
              hooks.shellcheck.enable = true;
              hooks.nixfmt-rfc-style = {
                enable = true;
                package = pkgs.nixfmt;
                excludes = [
                  ".direnv"
                  ".devenv"
                ];
              };
            };
          };
          devenv.shells.default = {
            name = "euvlok development shell";
            languages = {
              nix.enable = true;
              shell.enable = true;
            };
            git-hooks = {
              excludes = [
                ".direnv"
                ".devenv"
              ];
              hooks.nixfmt-rfc-style = {
                enable = true;
                excludes = [
                  ".direnv"
                  ".devenv"
                ];
                package = pkgs.nixfmt;
              };
              hooks.shellcheck.enable = true;
            };
            packages = builtins.attrValues {
              inherit (pkgs) git pre-commit;
              inherit (pkgs) nix-index nix-prefetch-github nix-prefetch-scripts;
            };
          };
          formatter = pkgs.nixfmt;

          apps = {
            auto-rebase = {
              type = "app";
              program =
                let
                  scriptFile = ./auto-rebase.sh;
                  script = pkgs.writeShellScriptBin "auto-rebase" ''
                    ${pkgs.lib.getExe' pkgs.nix "nix-shell"} ${scriptFile} "$@"
                  '';
                in
                "${script}/bin/auto-rebase";
            };
            browser-extension-update = {
              type = "app";
              program =
                let
                  scriptFile = ./modules/scripts/browser-extensions-update.cs;
                  script = pkgs.writeShellScriptBin "browser-extension" ''
                    ${pkgs.lib.getExe' pkgs.dotnetCorePackages.sdk_10_0-bin "dotnet"} run ${scriptFile} "$@"
                  '';
                in
                "${script}/bin/browser-extension";
            };
            nvidia-prefetch = {
              type = "app";
              program =
                let
                  scriptFile = ./modules/scripts/nvidia-prefetch.sh;
                  script = pkgs.writeShellScriptBin "nvidia-prefetch" ''
                    cd "$PWD" && ${pkgs.lib.getExe' pkgs.nix "nix-shell"} ${scriptFile} "$@"
                  '';
                in
                "${script}/bin/nvidia-prefetch";
            };

          };
        };

      flake = {
        nixosModules.default = import ./modules/nixos;
        darwinModules.default = ./modules/darwin;
        homeModules.default = ./modules/hm;
        homeModules.os = ./modules/hm/os;

        homeConfigurations = {
          ashuramaruzxc = import ./hosts/hm/ashuramaruzxc;
          bigshaq9999 = import ./hosts/hm/bigshaq9999;
          flameflag = import ./hosts/hm/flameflag;
          lay-by = import ./hosts/hm/lay-by;
          sm-idk = import ./hosts/hm/sm-idk;
        };

        nixosConfigurations = import ./hosts/linux { inherit inputs; };
        darwinConfigurations = import ./hosts/darwin { inherit inputs; };
      };
    };
}
