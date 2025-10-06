{
  description = "EUVlok Communal Dotfiles";

  inputs = {
    # --- Shared ---
    home-manager-stable.inputs.nixpkgs.follows = "nixpkgs";
    home-manager-stable.url = "github:nix-community/home-manager/release-25.05";
    home-manager-unstable.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    home-manager-unstable.url = "github:nix-community/home-manager";
    nixpkgs-unstable-small.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi";
    # This input is meant to be used for `-source` inputs and is rarely updated
    # to not cause constant rebuilds when updating generic unstable
    nixpkgs-source.url = "github:NixOS/nixpkgs/nixos-unstable";

    # --- 2husecondary ---
    nixpkgs-2husecondary.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager-2husecondary.url = "github:nix-community/home-manager/release-25.05";
    home-manager-2husecondary.inputs.nixpkgs.follows = "nixpkgs-2husecondary";

    # --- ashuramaruzxc ---
    nixpkgs-ashuramaruzxc.url = "github:NixOS/nixpkgs/release-25.05";
    home-manager-ashuramaruzxc.url = "github:nix-community/home-manager/release-25.05";
    home-manager-ashuramaruzxc.inputs.nixpkgs.follows = "nixpkgs-ashuramaruzxc";
    nix-darwin-ashuramaruzxc.url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
    nix-darwin-ashuramaruzxc.inputs.nixpkgs.follows = "nixpkgs-ashuramaruzxc";
    nixos-raspberrypi-ashuramaruzxc.url = "github:nvmd/nixos-raspberrypi";

    # --- bigshaq9999 ---
    nixpkgs-bigshaq9999.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager-bigshaq9999.url = "github:nix-community/home-manager/release-25.05";
    home-manager-bigshaq9999.inputs.nixpkgs.follows = "nixpkgs-bigshaq9999";
    nix-darwin-bigshaq9999.url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
    nix-darwin-bigshaq9999.inputs.nixpkgs.follows = "nixpkgs-bigshaq9999";

    # --- flameflag ---
    nixpkgs-flameflag.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager-flameflag.url = "github:nix-community/home-manager/release-25.05";
    home-manager-flameflag.inputs.nixpkgs.follows = "nixpkgs-flameflag";
    nix-darwin-flameflag.url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
    nix-darwin-flameflag.inputs.nixpkgs.follows = "nixpkgs-flameflag";

    # --- lay-by ---
    nixpkgs-lay-by.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager-lay-by.url = "github:nix-community/home-manager/release-25.05";
    home-manager-lay-by.inputs.nixpkgs.follows = "nixpkgs-lay-by";

    # --- sm-idk ---
    nixpkgs-sm-idk.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager-sm-idk.url = "github:nix-community/home-manager/release-25.05";
    home-manager-sm-idk.inputs.nixpkgs.follows = "nixpkgs-sm-idk";

    # --- Trivial ---
    base16-trivial.url = "github:SenchoPens/base16.nix";
    catppuccin-gtk.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    catppuccin-gtk.url = "github:catppuccin/nix/06f0ea19334bcc8112e6d671fd53e61f9e3ad63a";
    catppuccin-trivial.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    catppuccin-trivial.url = "github:catppuccin/nix/release-25.05";
    chaotic.inputs.home-manager.follows = "home-manager-unstable";
    chaotic.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    firefox-addons-trivial.url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
    flatpak-declerative-trivial.url = "github:in-a-dil-emma/declarative-flatpak";
    niri-flake-trivial.inputs.nixpkgs-stable.follows = "nixpkgs";
    niri-flake-trivial.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    niri-flake-trivial.url = "github:sodiboo/niri-flake";
    nix-vscode-extensions-trivial.inputs.flake-utils.follows = "flake-utils";
    nix-vscode-extensions-trivial.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    nix-vscode-extensions-trivial.url = "github:nix-community/nix-vscode-extensions";
    nix-vscode-server-trivial.inputs.flake-utils.follows = "flake-utils";
    nix-vscode-server-trivial.url = "github:nix-community/nixos-vscode-server";
    nixcord-trivial.inputs.flake-compat.follows = "";
    nixcord-trivial.inputs.flake-parts.follows = "flake-parts";
    nixcord-trivial.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    nixcord-trivial.url = "github:KaylorBen/nixcord";
    nixos-hardware-trivial.url = "github:NixOS/nixos-hardware";
    nur-trivial.inputs.flake-parts.follows = "flake-parts";
    nur-trivial.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    nur-trivial.url = "github:nix-community/NUR";
    nvidia-patch-trivial.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    nvidia-patch-trivial.inputs.utils.follows = "flake-utils";
    nvidia-patch-trivial.url = "github:icewind1991/nvidia-patch-nixos";
    sops-nix-trivial.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    sops-nix-trivial.url = "github:Mic92/sops-nix";
    spicetify-nix-trivial.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    spicetify-nix-trivial.url = "github:Gerg-L/spicetify-nix";
    stylix-trivial.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    stylix-trivial.url = "github:danth/stylix/release-25.05";
    zen-browser-trivial.inputs.home-manager.follows = "home-manager-unstable";
    zen-browser-trivial.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    zen-browser-trivial.url = "github:0xc000022070/zen-browser-flake";

    # ---- Source ----
    dis-source.inputs.nixpkgs.follows = "nixpkgs-source";
    dis-source.url = "github:FlameFlag/dis";
    hyprland-source.url = "github:hyprwm/Hyprland";
    lix-module-source.inputs.nixpkgs.follows = "nixpkgs-source";
    lix-module-source.url = "https://git.lix.systems/lix-project/nixos-module/archive/2.93.3-2.tar.gz";
    lix-source.inputs.flake-compat.follows = "";
    lix-source.inputs.nix2container.follows = "";
    lix-source.inputs.nixpkgs.follows = "nixpkgs";
    lix-source.inputs.pre-commit-hooks.follows = "";
    lix-source.url = "https://git.lix.systems/lix-project/lix/archive/2.93.3.tar.gz";
    nvf-source.inputs.flake-parts.follows = "flake-parts";
    nvf-source.inputs.nixpkgs.follows = "nixpkgs-source";
    nvf-source.url = "github:NotAShelf/nvf";
    rust-overlay-source.inputs.nixpkgs.follows = "nixpkgs-source";
    rust-overlay-source.url = "github:oxalica/rust-overlay";
    yazi-source.inputs.flake-utils.follows = "flake-utils";
    yazi-source.inputs.nixpkgs.follows = "nixpkgs-source";
    yazi-source.url = "github:sxyazi/yazi";

    # DO NOT OVERRIDE NIXPKGS
    anime-cursors-source.inputs.flake-parts.follows = "flake-parts";
    anime-cursors-source.url = "github:ashuramaruzxc/anime-cursors";
    anime-game-launcher-source.inputs.flake-compat.follows = "";
    anime-game-launcher-source.url = "github:ezKEa/aagl-gtk-on-nix";
    lightly-source.url = "github:Bali10050/Darkly";
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
                package = pkgs.nixfmt-rfc-style;
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
                package = pkgs.nixfmt-rfc-style;
              };
              hooks.shellcheck.enable = true;
            };
            packages = builtins.attrValues {
              inherit (pkgs) git pre-commit;
              inherit (pkgs) nix-index nix-prefetch-github nix-prefetch-scripts;
            };
          };
          formatter = pkgs.nixfmt-rfc-style;
        };

      flake = {
        nixosModules = import ./modules/nixos;
        darwinModules = import ./modules/darwin;
        homeModules = import ./modules/hm;
        crossModules = import ./modules/cross;

        nixosConfigurations = import ./hosts/linux { inherit inputs; };
        darwinConfigurations = import ./hosts/darwin { inherit inputs; };
      };
    };
}
