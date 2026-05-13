{
  description = " A very bad attempt at making a nice personal NixOS config ";

  inputs = {
    # First‑party (official)
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home‑manager
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Third‑party custom flakes
    niri = {
      url = "github:sodiboo/niri-flake";
    };

    stylix = {
      url = "github:nix-community/stylix/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-flatpak.url = "github:gmodena/nix-flatpak"; # unstable branch

    # quickshell = {
    #   url = "github:outfoxxed/quickshell";
    #   inputs.nixpkgs.follows = "nixpkgs-unstable";
    # };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixcord = {
      url = "github:FlameFlag/nixcord";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    euvlok-pkgs.url = "github:euvlok/pkgs";

    apple-silicon.url = "github:nix-community/nixos-apple-silicon";

    steam-asahi.url = "github:sm-idk/steam-asahi";
  };

  outputs = inputs: {
    nixosModules.default = import ./modules/core;
    homeModules.default = import ./home/modules;
    nixosConfigurations = import ./hosts { inherit inputs; };
  };
}
