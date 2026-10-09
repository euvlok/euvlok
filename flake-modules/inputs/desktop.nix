{
  flake-file.inputs = {
    browser.inputs.flake-parts.follows = "flake-parts";
    browser.inputs.home-manager.follows = "home-manager";
    browser.inputs.nix-darwin.follows = "nix-darwin";
    browser.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    browser.url = "github:4evy/browser";
    catppuccin.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    catppuccin.url = "github:catppuccin/nix";
    nix4vscode.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    nix4vscode.inputs.systems.follows = "flake-utils/systems";
    nix4vscode.url = "github:nix-community/nix4vscode";
    nixcord.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
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
    zen-browser.inputs.home-manager.follows = "home-manager";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
  };
}
