{
  flake-file.inputs = {
    anime-cursors-source = {
      flake = false;
      url = "github:4evy/anime-cursors";
    };
    cursorgen-source = {
      flake = false;
      url = "github:4evy/cursorgen";
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
    ecolinker = {
      inputs = {
        flake-parts.follows = "users-flake-parts";
        nixpkgs.follows = "users-nixpkgs-unstable-small";
      };
      url = "github:v4rakh/ecolinker";
    };
    flatpak-declarative.url = "github:in-a-dil-emma/declarative-flatpak";
    nix-jetbrains-plugins = {
      inputs = {
        flake-compat.follows = "";
        nixpkgs.follows = "users-nixpkgs-unstable-small";
        systems.follows = "users-flake-utils/systems";
      };
      url = "github:nix-community/nix-jetbrains-plugins";
    };
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
  };
}
