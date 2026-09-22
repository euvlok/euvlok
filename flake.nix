{
  description = "EUVlok shared NixOS, nix-darwin, and Home Manager configurations";

  nixConfig = {
    extra-substituters = [ "https://catppuccin.cachix.org" ];
    extra-trusted-public-keys = [
      "catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732IysmU="
    ];
  };

  inputs = {
    # --- Shared ---
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
    eupkgs.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    eupkgs.url = "github:euvlok/pkgs";
    flake-schemas.url = "https://flakehub.com/f/DeterminateSystems/flake-schemas/*.tar.gz";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable-small.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-darwin.url = "github:nix-darwin/nix-darwin";

    # --- Trivial ---
    browser.inputs.home-manager.follows = "home-manager";
    browser.inputs.nix-darwin.follows = "nix-darwin";
    browser.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    browser.url = "github:4evy/browser";
    catppuccin-gtk.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    catppuccin-gtk.url = "github:catppuccin/nix/06f0ea19334bcc8112e6d671fd53e61f9e3ad63a";
    catppuccin.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    catppuccin.url = "github:catppuccin/nix";
    nix4vscode.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    nix4vscode.inputs.systems.follows = "flake-utils/systems";
    nix4vscode.url = "github:nix-community/nix4vscode";
    nixcord.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    nixcord.url = "github:FlameFlag/nixcord";
    nvidia-patch.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    nvidia-patch.inputs.utils.follows = "flake-utils";
    nvidia-patch.url = "github:icewind1991/nvidia-patch-nixos";
    pared.inputs.nixpkgs.follows = "nixpkgs";
    pared.url = "github:4evy/pared";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    sops-nix.url = "github:Mic92/sops-nix";
    zen-browser.inputs.home-manager.follows = "home-manager";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs-unstable-small";
    zen-browser.url = "github:0xc000022070/zen-browser-flake";

    # Infra / Shared / Core Inputs
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-utils.url = "github:numtide/flake-utils"; # ONLY Exists to override inputs (NOT TO BE USED)
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } ./flake-modules;
}
