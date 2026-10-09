{
  flake-file.inputs = {
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/=3.23.1";
    eupkgs.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    eupkgs.url = "github:euvlok/pkgs";
    flake-schemas.url = "https://flakehub.com/f/DeterminateSystems/flake-schemas/*.tar.gz";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    nixpkgs-unstable-small.url = "https://channels.nixos.org/nixos-unstable-small/nixexprs.tar.zst";
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-darwin.url = "github:nix-darwin/nix-darwin";

    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-utils.url = "github:numtide/flake-utils"; # ONLY Exists to override inputs (NOT TO BE USED)
    flake-file.url = "github:denful/flake-file";
  };
}
