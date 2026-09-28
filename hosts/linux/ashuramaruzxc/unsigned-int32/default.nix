{
  flatpakModule,
  homeModule,
  sharedModule,
}:
_: {
  imports = [
    sharedModule
    ./configuration.nix
    homeModule
    { sops.defaultSopsFile = ../../../../secrets/ashuramaruzxc_shared.yaml; }
    {
      catppuccin = {
        enable = true;
        flavor = "mocha";
        accent = "flamingo";
      };
    }
    flatpakModule
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
      euvlok.nixos = {
        cosmic.enable = true;
        gnome.enable = true;
        nvidia.enable = true;
        plasma.enable = true;
        steam.enable = true;
      };
    }
  ];
}
