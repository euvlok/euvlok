{
  description = "EUVlok Communal Dotfiles";

  inputs = {
    # --- 2husecondary ---
    nixpkgs-2husecondary.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager-2husecondary.url = "github:nix-community/home-manager";
    home-manager-2husecondary.inputs.nixpkgs.follows = "nixpkgs-2husecondary";

    # --- ashuramaruzxc ---
    nixpkgs-ashuramaruzxc.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager-ashuramaruzxc.url = "github:nix-community/home-manager";
    home-manager-ashuramaruzxc.inputs.nixpkgs.follows = "nixpkgs-ashuramaruzxc";
    nix-darwin-ashuramaruzxc.url = "github:LnL7/nix-darwin";
    nix-darwin-ashuramaruzxc.inputs.nixpkgs.follows = "nixpkgs-ashuramaruzxc";

    # --- bigshaq9999 ---
    nixpkgs-bigshaq9999.url = "github:NixOS/nixpkgs/nixos-24.11";
    home-manager-bigshaq9999.url = "github:nix-community/home-manager/release-24.11";
    home-manager-bigshaq9999.inputs.nixpkgs.follows = "nixpkgs-bigshaq9999";
    nix-darwin-bigshaq9999.url = "github:LnL7/nix-darwin";
    nix-darwin-bigshaq9999.inputs.nixpkgs.follows = "nixpkgs-donteatoreo";

    # --- donteatoreo ---
    nixpkgs-donteatoreo.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    home-manager-donteatoreo.url = "github:nix-community/home-manager";
    home-manager-donteatoreo.inputs.nixpkgs.follows = "nixpkgs-donteatoreo";
    nix-darwin-donteatoreo.url = "github:LnL7/nix-darwin";
    nix-darwin-donteatoreo.inputs.nixpkgs.follows = "nixpkgs-donteatoreo";

    # --- lay-by ---
    nixpkgs-lay-by.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager-lay-by.url = "github:nix-community/home-manager";
    home-manager-lay-by.inputs.nixpkgs.follows = "nixpkgs-lay-by";

    # --- Unstable/Stable Shared ---
    home-manager-stable.inputs.nixpkgs.follows = "nixpkgs";
    home-manager-stable.url = "github:nix-community/home-manager/release-24.11";
    home-manager-unstable.inputs.nixpkgs.follows = "nixpkgs-unstable";
    home-manager-unstable.url = "github:nix-community/home-manager";
    nixpkgs-unstable-small.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    # --- Trivial ---
    base16-trivial.url = "github:SenchoPens/base16.nix";
    catppuccin-trivial.inputs.nixpkgs.follows = "nixpkgs-unstable";
    catppuccin-trivial.url = "github:catppuccin/nix";
    firefox-addons-trivial.url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
    flatpak-declerative-trivial.url = "github:in-a-dil-emma/declarative-flatpak";
    niri-flake-trivial.inputs.nixpkgs-stable.follows = "nixpkgs";
    niri-flake-trivial.inputs.nixpkgs.follows = "nixpkgs-unstable";
    niri-flake-trivial.url = "github:sodiboo/niri-flake";
    nix-vscode-extensions-trivial.inputs.flake-utils.follows = "flake-utils";
    nix-vscode-extensions-trivial.inputs.nixpkgs.follows = "nixpkgs-unstable";
    nix-vscode-extensions-trivial.url = "github:nix-community/nix-vscode-extensions";
    nix-vscode-server-trivial.inputs.flake-utils.follows = "flake-utils";
    nix-vscode-server-trivial.url = "github:nix-community/nixos-vscode-server";
    nixcord-trivial.inputs.flake-compat.follows = "";
    nixcord-trivial.inputs.nixpkgs.follows = "nixpkgs-unstable";
    nixcord-trivial.inputs.treefmt-nix.follows = "";
    nixcord-trivial.url = "github:KaylorBen/nixcord";
    nixos-hardware-trivial.url = "github:NixOS/nixos-hardware";
    nur-trivial.inputs.flake-parts.follows = "flake-parts";
    nur-trivial.inputs.nixpkgs.follows = "nixpkgs-unstable";
    nur-trivial.url = "github:nix-community/NUR";
    nvidia-patch-trivial.inputs.utils.follows = "flake-utils";
    nvidia-patch-trivial.inputs.nixpkgs.follows = "nixpkgs-unstable";
    nvidia-patch-trivial.url = "github:icewind1991/nvidia-patch-nixos";
    sops-nix-trivial.inputs.nixpkgs.follows = "nixpkgs-unstable";
    sops-nix-trivial.url = "github:Mic92/sops-nix";
    spicetify-nix-trivial.inputs.nixpkgs.follows = "nixpkgs-unstable";
    spicetify-nix-trivial.url = "github:Gerg-L/spicetify-nix";
    stylix-trivial.inputs.flake-utils.follows = "flake-utils";
    stylix-trivial.inputs.git-hooks.follows = "";
    stylix-trivial.inputs.home-manager.follows = "home-manager-unstable";
    stylix-trivial.inputs.nixpkgs.follows = "nixpkgs-unstable";
    stylix-trivial.url = "github:danth/stylix";
    zen-browser-trivial.inputs.home-manager.follows = "home-manager-unstable";
    zen-browser-trivial.inputs.nixpkgs.follows = "nixpkgs-unstable";
    zen-browser-trivial.url = "github:0xc000022070/zen-browser-flake";

    # ---- Source ----
    dis-source.inputs.nixpkgs.follows = "nixpkgs-unstable";
    dis-source.url = "github:DontEatOreo/dis/develop";
    helix-source.inputs.nixpkgs.follows = "nixpkgs";
    helix-source.url = "github:helix-editor/helix";
    hyprland-source.url = "github:hyprwm/Hyprland";
    jj-vcs-source.inputs.flake-utils.follows = "flake-utils";
    jj-vcs-source.inputs.nixpkgs.follows = "nixpkgs-unstable";
    jj-vcs-source.url = "github:jj-vcs/jj";
    lix-module-source.inputs.nixpkgs.follows = "nixpkgs-unstable";
    lix-module-source.url = "https://git.lix.systems/lix-project/nixos-module/archive/2.93.0.tar.gz";
    nil-source.inputs.flake-utils.follows = "flake-utils";
    nil-source.inputs.nixpkgs.follows = "nixpkgs-unstable";
    nil-source.url = "github:oxalica/nil";
    nvf-source.inputs.flake-parts.follows = "flake-parts";
    nvf-source.inputs.flake-utils.follows = "flake-utils";
    nvf-source.inputs.nil.follows = "nil-source";
    nvf-source.inputs.nixpkgs.follows = "nixpkgs-unstable";
    nvf-source.url = "github:NotAShelf/nvf";
    yazi-source.inputs.flake-utils.follows = "flake-utils";
    yazi-source.inputs.nixpkgs.follows = "nixpkgs-unstable";
    yazi-source.url = "github:sxyazi/yazi";

    # DO NOT OVERRIDE NIXPKGS
    anime-cursors-source.inputs.flake-parts.follows = "flake-parts";
    anime-cursors-source.url = "github:ashuramaruzxc/anime-cursors";
    anime-game-launcher-source.inputs.flake-compat.follows = "";
    anime-game-launcher-source.url = "github:ezKEa/aagl-gtk-on-nix";
    lightly-source.url = "github:Bali10050/Darkly";

    # Infra / Shared / Core Inputs
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-utils.url = "github:numtide/flake-utils"; # ONLY Exists to override inputs (NOT TO BE USED)
    devenv.url = "github:cachix/devenv";
    devenv.inputs.nixpkgs.follows = "nixpkgs-unstable";
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";
    pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs-unstable";
    pre-commit-hooks.inputs.flake-compat.follows = "";
    mk-shell-bin.url = "github:rrbutani/nix-mk-shell-bin";
    nix2container.url = "github:nlewo/nix2container";
    nix2container.inputs.flake-utils.follows = "flake-utils";
    nix2container.inputs.nixpkgs.follows = "nixpkgs-unstable";
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
            pre-commit = {
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
        nixosConfigurations = import ./hosts/linux { inherit inputs; };
        darwinConfigurations = import ./hosts/darwin { inherit inputs; };
      };
    };
}
