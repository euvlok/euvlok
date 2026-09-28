{
  diskoModule,
  flatpakModule,
  homeModule,
  raspberryPiModules,
  sharedModule,
}:
_: {
  imports = [
    sharedModule
    ./configuration.nix
    homeModule
    diskoModule
  ]
  ++ raspberryPiModules
  ++ [
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
      };
    }
    { euvlok.nixos.plasma.enable = true; }
  ];
}
