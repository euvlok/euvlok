{
  configurationModule,
  homeModule,
  sharedModule,
  stylixModule,
  unstableSource,
}:
_: {
  imports = [
    sharedModule
    configurationModule
    homeModule
    stylixModule
    ../shared/stylix.nix
    {
      euvlok.nixpkgs.unstableSource = unstableSource;
      euvlok.nixos = {
        gui = {
          enable = true;
          wlrootsWorkarounds = false;
        };
        zram.enable = true;
      };
    }
  ];
}
