{
  description = "EUVlok Communal Dotfiles";

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
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
          formatter = pkgs.nixfmt-rfc-style;
        };

      flake = {
        nixosConfigurations = import ./hosts/linux { inherit inputs; };
        darwinConfigurations = import ./hosts/darwin { inherit inputs; };
      };
    };

  inputs = {
    # Flake-Parts and Devenv
    flake-parts.url = "github:hercules-ci/flake-parts";
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";
    pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs-unstable";
    pre-commit-hooks.inputs.flake-compat.follows = "";
    # --------------------------------------------------

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11"; # For compatibility reasons
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable"; # Shared unstable

    nixpkgs-ashuramaruzxc.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-bigshaq9999.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-donteatoreo.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    nixpkgs-lay-by.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager-ashuramaruzxc.url = "github:nix-community/home-manager/release-24.11";
    home-manager-ashuramaruzxc.inputs.nixpkgs.follows = "nixpkgs-ashuramaruzxc";

    home-manager-bigshaq9999.url = "github:nix-community/home-manager";
    home-manager-bigshaq9999.inputs.nixpkgs.follows = "nixpkgs-bigshaq9999";

    home-manager-donteatoreo.url = "github:nix-community/home-manager";
    home-manager-donteatoreo.inputs.nixpkgs.follows = "nixpkgs-donteatoreo";

    home-manager-lay-by.url = "github:nix-community/home-manager";
    home-manager-lay-by.inputs.nixpkgs.follows = "nixpkgs-lay-by";

    nix-darwin-ashuramaruzxc.inputs.nixpkgs.follows = "nixpkgs-ashuramaruzxc";
    nix-darwin-ashuramaruzxc.url = "github:LnL7/nix-darwin/nix-darwin-24.11";

    nix-darwin-donteatoreo.inputs.nixpkgs.follows = "nixpkgs-donteatoreo";
    nix-darwin-donteatoreo.url = "github:LnL7/nix-darwin";

    nixcord.url = "github:KaylorBen/nixcord";
    nixcord.inputs.nixpkgs.follows = "nixpkgs-unstable";
    nixcord.inputs.flake-compat.follows = "";
    nixcord.inputs.treefmt-nix.follows = "";

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    nix-vscode-extensions.inputs.nixpkgs.follows = "nixpkgs-unstable";

    lightly.url = "github:Bali10050/Darkly";
    lightly.inputs.nixpkgs.follows = "nixpkgs-unstable";

    firefox-addons.url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";

    nil.url = "github:oxalica/nil";
    nil.inputs.nixpkgs.follows = "nixpkgs-unstable";

    nvf.url = "github:NotAShelf/nvf";
    nvf.inputs.nixpkgs.follows = "nixpkgs-unstable";
    nvf.inputs.flake-parts.follows = "flake-parts";
    nvf.inputs.nil.follows = "nil";

    niri-flake.url = "github:sodiboo/niri-flake";
    niri-flake.inputs.nixpkgs.follows = "nixpkgs-unstable";
    niri-flake.inputs.nixpkgs-stable.follows = "nixpkgs";

    nur.url = "github:nix-community/NUR";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs-unstable";

    catppuccin.url = "github:catppuccin/nix";
    catppuccin.inputs.nixpkgs.follows = "nixpkgs-unstable";

    dis.url = "github:DontEatOreo/dis/develop";
    dis.inputs.nixpkgs.follows = "nixpkgs-unstable";

    nvidia-patch.url = "github:icewind1991/nvidia-patch-nixos";
    nvidia-patch.inputs.nixpkgs.follows = "nixpkgs-lay-by";

    hyprland.url = "github:hyprwm/Hyprland";

    stylix.url = "github:danth/stylix";
    stylix.inputs.nixpkgs.follows = "nixpkgs-unstable";
    stylix.inputs.git-hooks.follows = "";
    stylix.inputs.home-manager.follows = "home-manager-lay-by";

    base16.url = "github:SenchoPens/base16.nix";

    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
    spicetify-nix.inputs.nixpkgs.follows = "nixpkgs-lay-by";

    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs-unstable";
  };
}
