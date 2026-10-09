{
  flake-file.inputs = {
    nixpkgs-unstable.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
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
  };
}
