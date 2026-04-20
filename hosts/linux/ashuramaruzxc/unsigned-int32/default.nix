inputs:
let
  inherit (import ../../../../lib/catppuccin.nix) mkCatppuccin hosts;
in
inputs.nixpkgs.lib.nixosSystem {
  specialArgs = { inherit inputs; };
  modules = [
    inputs.self.nixosModules.default
    ./configuration.nix
    ./home.nix
    { sops.defaultSopsFile = ../../../../secrets/ashuramaruzxc_unsigned-int32.yaml; }
    (mkCatppuccin hosts.unsigned-int32)
    inputs.anime-game-launcher-source.nixosModules.default
    {
      programs.anime-game-launcher.enable = true;
      programs.honkers-railway-launcher.enable = true;
      aagl.enableNixpkgsReleaseBranchCheck = false;
    }
    inputs.flatpak-declerative-trivial.nixosModules.default
    {
      services.flatpak = {
        enable = true;
        remotes = {
          "flathub" = "https://dl.flathub.org/repo/flathub.flatpakrepo";
          "flathub-beta" = "https://dl.flathub.org/beta-repo/flathub-beta.flatpakrepo";
        };
      };
    }
    {
      nixos = {
        plasma.enable = true;
        gnome.enable = true;
        nvidia.enable = true;
        steam.enable = true;
      };
    }
  ];
}
