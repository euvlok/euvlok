{
  flake-file.inputs = {
    users-flake-parts.inputs.nixpkgs-lib.follows = "users-nixpkgs";
    users-flake-parts.url = "github:hercules-ci/flake-parts";
    users-flake-utils.url = "github:numtide/flake-utils";
    users-nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
    users-nixpkgs-unstable-small.url = "https://channels.nixos.org/nixos-unstable-small/nixexprs.tar.zst";
    users-flake-file.url = "github:denful/flake-file";
  };
}
