{
  flake-file.inputs = {
    artcraft.inputs.nixpkgs.follows = "users-nixpkgs";
    artcraft.url = "github:Hy4ri/artcraft-flake";
    spicetify-nix = {
      inputs = {
        nixpkgs.follows = "users-nixpkgs";
        systems.follows = "users-flake-utils/systems";
      };
      url = "github:Gerg-L/spicetify-nix";
    };
    stylix = {
      inputs = {
        flake-parts.follows = "users-flake-parts";
        nixpkgs.follows = "users-nixpkgs";
        systems.follows = "users-flake-utils/systems";
      };
      url = "github:danth/stylix";
    };
  };
}
