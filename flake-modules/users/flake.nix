{
  description = "EUVlok contributor-owned flake inputs";

  inputs = {
    nixpkgs-source.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Ashuramaruzxc
    anime-cursors-source.inputs.devenv.follows = "users-devenv";
    anime-cursors-source.inputs.flake-parts.follows = "users-flake-parts";
    anime-cursors-source.inputs.nixpkgs-python.inputs.flake-compat.follows = "";
    anime-cursors-source.inputs.mk-shell-bin.follows = "users-mk-shell-bin";
    anime-cursors-source.inputs.nix2container.follows = "users-nix2container";
    anime-cursors-source.inputs.pre-commit-hooks.follows = "users-pre-commit-hooks";
    anime-cursors-source.url = "github:ashuramaruzxc/anime-cursors";
    anime-game-launcher-source.inputs.flake-compat.follows = "";
    anime-game-launcher-source.inputs.rust-overlay.inputs.nixpkgs.follows =
      "users-nixpkgs-unstable-small";
    anime-game-launcher-source.url = "github:ezKEa/aagl-gtk-on-nix";
    disko-rpi.inputs.nixpkgs.follows = "users-nixpkgs";
    disko-rpi.url = "github:nvmd/disko/gpt-attrs";
    flatpak-declerative-trivial.url = "github:in-a-dil-emma/declarative-flatpak";
    nix-homebrew-trivial.url = "github:zhaofengli/nix-homebrew";
    nixos-raspberrypi.inputs.flake-compat.follows = "";
    nixos-raspberrypi.inputs.nixpkgs.follows = "users-nixpkgs";
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi";
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

    # Bigshaq9999
    dis-source.inputs.nixpkgs.follows = "nixpkgs-source";
    dis-source.url = "github:FlameFlag/dis";

    # Lay-by
    spicetify-nix-trivial.inputs.nixpkgs.follows = "users-nixpkgs-unstable-small";
    spicetify-nix-trivial.inputs.systems.follows = "users-flake-utils/systems";
    spicetify-nix-trivial.url = "github:Gerg-L/spicetify-nix";

    # Sm-idk
    nixos-apple-silicon.inputs.nixpkgs.follows = "users-nixpkgs";
    nixos-apple-silicon.url = "github:nix-community/nixos-apple-silicon";
    noctalia-trivial.inputs.nixpkgs.follows = "users-nixpkgs-unstable-small";
    noctalia-trivial.url = "github:noctalia-dev/noctalia-shell";
    steam-asahi.inputs.nixpkgs.follows = "users-nixpkgs";
    steam-asahi.url = "github:sm-idk/steam-asahi";

    # Support inputs needed by contributor-owned sources.
    users-devenv.inputs.cachix.inputs.flake-compat.follows = "";
    users-devenv.inputs.crate2nix.follows = "";
    users-devenv.inputs.flake-compat.follows = "";
    users-devenv.inputs.flake-parts.follows = "users-flake-parts";
    users-devenv.inputs.git-hooks.inputs.gitignore.follows = "";
    users-devenv.inputs.nixd.follows = "";
    users-devenv.inputs.nixpkgs.follows = "users-nixpkgs-unstable-small";
    users-devenv.url = "github:cachix/devenv";
    users-flake-parts.url = "github:hercules-ci/flake-parts";
    users-flake-utils.url = "github:numtide/flake-utils";
    users-mk-shell-bin.url = "github:rrbutani/nix-mk-shell-bin";
    users-nix2container.inputs.nixpkgs.follows = "users-nixpkgs-unstable-small";
    users-nix2container.url = "github:nlewo/nix2container";
    users-nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    users-nixpkgs-unstable-small.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    users-pre-commit-hooks.inputs.flake-compat.follows = "";
    users-pre-commit-hooks.inputs.gitignore.follows = "";
    users-pre-commit-hooks.inputs.nixpkgs.follows = "users-nixpkgs-unstable-small";
    users-pre-commit-hooks.url = "github:cachix/git-hooks.nix";
  };

  outputs = _: { };
}
