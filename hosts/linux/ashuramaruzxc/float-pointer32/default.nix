{ inputs, euvlok, ... }:
{
  unsigned-int32 = inputs.nixpkgs-ashuramaruzxc.lib.nixosSystem {
    specialArgs = { inherit inputs euvlok; };
    modules = [
      ./configuration.nix
      ./home.nix
      inputs.sops-nix-trivial.nixosModules.sops
      {
        sops = {
          age.keyFile = "/var/lib/sops/age/keys.txt";
          defaultSopsFile = ../../../../secrets/ashuramaruzxc_unsigned-int32.yaml;
        };
      }
      inputs.catppuccin-trivial.nixosModules.catppuccin
      {
        catppuccin = {
          enable = true;
          flavor = "mocha";
          accent = "flamingo";
        };
      }
      ../../../../modules/nixos
      ../../../../modules/cross
      {
        nixos = {
          plasma.enable = true;
          gnome.enable = true;
          nvidia.enable = true;
          steam.enable = true;
        };
        cross = {
          nix.enable = true;
          nixpkgs = {
            enable = true;
            cudaSupport = true;
          };
        };
      }
      inputs.anime-game-launcher-source.nixosModules.default
      {
        programs.anime-game-launcher.enable = true;
        programs.honkers-railway-launcher.enable = true;
        aagl.enableNixpkgsReleaseBranchCheck = false;
      }
      inputs.flatpak-declerative-trivial.nixosModule
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
        _module.args.unstable = inputs.nixpkgs-unstable;
        _module.args.unstable-small = inputs.nixpkgs-unstable-small;
      }
    ];
  };
}
