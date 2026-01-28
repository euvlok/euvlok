{ inputs, ... }:
let
  inherit (import ../shared/host-lib.nix { inherit inputs; }) mkHostSystem;
in
{
  unsigned-int32 = mkHostSystem {
    modules = [
      inputs.self.nixosModules.default
      ./configuration.nix
      ./home.nix
    ];
    sopsFile = ../../../../secrets/ashuramaruzxc_unsigned-int32.yaml;
    catppuccinAccent = "flamingo";
    extraModules = [
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
          cosmic.enable = true;
          nvidia.enable = true;
          steam.enable = true;
        };
      }
    ];
  };
}
