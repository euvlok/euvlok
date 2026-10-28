{
  flake-file.inputs = {
    tweezle.inputs.flake-parts.follows = "flake-parts";
    tweezle.inputs.home-manager.follows = "home-manager";
    tweezle.inputs.nix-darwin.follows = "";
    tweezle.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    tweezle.url = "github:4evy/tweezle";
    catppuccin.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    catppuccin.url = "github:catppuccin/nix";
    helix.inputs.nixpkgs.follows = "nixpkgs";
    helix.url = "github:gj1118/helix";
    nix4vscode.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    nix4vscode.inputs.systems.follows = "flake-utils/systems";
    nix4vscode.url = "github:nix-community/nix4vscode";
    nixcord.inputs.home-manager.follows = "home-manager";
    nixcord.inputs.nix-darwin.follows = "";
    nixcord.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    nixcord.inputs.nixpkgs-ci.follows = "nixcord/nixpkgs-packages";
    nixcord.url = "github:4evy/nixcord";
    nvidia-patch.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    nvidia-patch.inputs.utils.follows = "flake-utils";
    nvidia-patch.url = "github:icewind1991/nvidia-patch-nixos";
    pared.inputs.nixpkgs.follows = "nixpkgs";
    pared.url = "github:4evy/pared";
    raycast.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    raycast.url = "github:4evy/raycast";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    sops-nix.url = "github:Mic92/sops-nix";
    zen-browser.flake = false;
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
  };
}
