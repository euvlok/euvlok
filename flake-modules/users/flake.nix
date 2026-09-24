{
  description = "EUVlok contributor-owned flake inputs";

  inputs = {
    # Ashuramaruzxc
    nixpkgs-container.url = "github:NixOS/nixpkgs/pull/566547/head";
    anime-cursors-source = {
      inputs = {
        devenv.follows = "users-devenv";
        flake-parts.follows = "users-flake-parts";
        mk-shell-bin.follows = "";
        nix2container.follows = "";
        nixpkgs-python.inputs.flake-compat.follows = "";
        pre-commit-hooks.follows = "users-devenv/git-hooks";
      };
      url = "github:ashuramaruzxc/anime-cursors";
    };
    codex-desktop-linux = {
      inputs = {
        flake-utils.follows = "users-flake-utils";
        nixpkgs.follows = "users-nixpkgs-unstable-small";
      };
      url = "github:ilysenko/codex-desktop-linux";
    };
    disko-rpi = {
      inputs.nixpkgs.follows = "users-nixpkgs";
      url = "github:nvmd/disko/gpt-attrs";
    };
    flatpak-declarative.url = "github:in-a-dil-emma/declarative-flatpak";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    nixos-raspberrypi = {
      inputs = {
        flake-compat.follows = "";
        nixpkgs.follows = "users-nixpkgs";
      };
      url = "github:nvmd/nixos-raspberrypi";
    };
    homebrew-core-source = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask-source = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-crc-source = {
      url = "github:cfergeau/homebrew-crc";
      flake = false;
    };

    # Lay-by
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    spicetify-nix = {
      inputs = {
        nixpkgs.follows = "users-nixpkgs-unstable-small";
        systems.follows = "users-flake-utils/systems";
      };
      url = "github:Gerg-L/spicetify-nix";
    };
    stylix = {
      inputs = {
        flake-parts.follows = "users-flake-parts";
        nixpkgs.follows = "users-nixpkgs-unstable-small";
        systems.follows = "users-flake-utils/systems";
      };
      url = "github:danth/stylix";
    };

    # Support inputs needed by contributor-owned sources.
    users-devenv = {
      inputs = {
        cachix.inputs.flake-compat.follows = "";
        crate2nix.follows = "";
        flake-compat.follows = "";
        flake-parts.follows = "users-flake-parts";
        nixd.follows = "";
        nixpkgs.follows = "users-nixpkgs-unstable-small";
      };
      url = "github:cachix/devenv";
    };
    users-flake-parts.url = "github:hercules-ci/flake-parts";
    users-flake-utils.url = "github:numtide/flake-utils";
    users-nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    users-nixpkgs-unstable-small.url = "github:NixOS/nixpkgs/nixos-unstable-small";
  };

  outputs = _: { };
}
