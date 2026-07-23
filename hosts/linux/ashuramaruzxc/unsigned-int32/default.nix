inputs:
# inputs.nixpkgs-patcher.lib.nixosSystem {
inputs.nixpkgs.lib.nixosSystem {
  # nixpkgsPatcher.inputs = inputs;
  specialArgs = { inherit inputs; };
  modules = [
    inputs.self.nixosModules.default
    ./configuration.nix
    ./home.nix
    { sops.defaultSopsFile = ../../../../secrets/ashuramaruzxc_unsigned-int32.yaml; }
    {
      catppuccin = {
        enable = true;
        flavor = "mocha";
        accent = "flamingo";
      };
    }
    inputs.flatpak-declerative-trivial.nixosModules.default
    {
      services.flatpak = {
        enable = true;
        remotes = {
          "flathub" = "https://dl.flathub.org/repo/flathub.flatpakrepo";
          "flathub-beta" = "https://dl.flathub.org/beta-repo/flathub-beta.flatpakrepo";
        };
        overrides.global.environment = {
          GSK_RENDERER = "vulkan";
          QSG_RHI_BACKEND = "vulkan";
        };
      };
    }
    {
      nixos = {
        cosmic.enable = true;
        gnome.enable = true;
        nvidia.enable = true;
        plasma.enable = true;
        steam.enable = true;
      };
    }
  ];
}
