{
  description = "EUVlok Communal Dotfiles";

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.devenv.flakeModule ];
      systems = [
        # Linux
        "x86_64-linux"
        "aarch64-linux"
        # Że macos(EU approved)
        "x86_64-darwin"
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

  inputs = {
    # Flake-Parts and Devenv
    flake-parts.url = "github:hercules-ci/flake-parts";
    devenv.url = "github:cachix/devenv";
    devenv.inputs.nixpkgs.follows = "nixpkgs-unstable";
    nix2container.url = "github:nlewo/nix2container";
    nix2container.inputs.nixpkgs.follows = "nixpkgs-unstable";
    mk-shell-bin.url = "github:rrbutani/nix-mk-shell-bin";
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";
    pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs-unstable";
    pre-commit-hooks.inputs.flake-compat.follows = "";
    # --------------------------------------------------

    nixpkgs-24_05.url = "github:NixOS/nixpkgs/nixos-24.05"; # For compatibility reasons right now
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11"; # For compatibility reasons in the future
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable"; # Shared unstable
    nixpkgs-unstable-small.url = "github:NixOS/nixpkgs/nixos-unstable-small"; # Shared unstable small

    nixpkgs-2husecondary.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-ashuramaruzxc.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-bigshaq9999.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-donteatoreo.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    nixpkgs-lay-by.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Generic for shared usage purpose
    home-manager-stable.url = "github:nix-community/home-manager/release-24.11";
    home-manager-stable.inputs.nixpkgs.follows = "nixpkgs";

    home-manager-unstable.url = "github:nix-community/home-manager";
    home-manager-unstable.inputs.nixpkgs.follows = "nixpkgs-unstable";

    home-manager-2husecondary.url = "github:nix-community/home-manager/release-24.11";
    home-manager-2husecondary.inputs.nixpkgs.follows = "nixpkgs-2husecondary";

    home-manager-ashuramaruzxc.url = "github:nix-community/home-manager/release-24.11";
    home-manager-ashuramaruzxc.inputs.nixpkgs.follows = "nixpkgs-ashuramaruzxc";

    home-manager-bigshaq9999.url = "github:nix-community/home-manager";
    home-manager-bigshaq9999.inputs.nixpkgs.follows = "nixpkgs-bigshaq9999";

    home-manager-donteatoreo.url = "github:nix-community/home-manager";
    home-manager-donteatoreo.inputs.nixpkgs.follows = "nixpkgs-donteatoreo";

    home-manager-lay-by.url = "github:nix-community/home-manager";
    home-manager-lay-by.inputs.nixpkgs.follows = "nixpkgs-lay-by";

    #! @ashuramaruzxc: for now nix-darwin only properly works on unstable
    nix-darwin-ashuramaruzxc.inputs.nixpkgs.follows = "nixpkgs-donteatoreo";
    nix-darwin-ashuramaruzxc.url = "github:LnL7/nix-darwin";

    nix-darwin-bigshaq9999.inputs.nixpkgs.follows = "nixpkgs-donteatoreo";
    nix-darwin-bigshaq9999.url = "github:LnL7/nix-darwin";

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
    #! do not override lightly.inputs.nixpkgs.follows = "nixpkgs-unstable";

    firefox-addons.url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";

    flatpak-declerative.url = "github:in-a-dil-emma/declarative-flatpak";

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

    anime-game-launcher-ashuramaruzxc.url = "github:ezKEa/aagl-gtk-on-nix/release-24.11";
    anime-game-launcher.inputs.nixpkgs.follows = "nixpkgs-ashuramaruzxc";

    anime-game-launcher-2husecondary.url = "github:ezKEa/aagl-gtk-on-nix/release-24.11";
    anime-game-launcher-2husecondary.inputs.nixpkgs.follows = "nixpkgs-2husecondary";
  };
}
