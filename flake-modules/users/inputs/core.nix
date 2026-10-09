{
  flake-file.inputs = {
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
    users-nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
    users-nixpkgs-unstable-small.url = "https://channels.nixos.org/nixos-unstable-small/nixexprs.tar.zst";
    users-flake-file.url = "github:denful/flake-file";
  };
}
