{
  homeModule,
  sharedModules,
}:
_: {
  imports = sharedModules ++ [
    ./configuration.nix
    homeModule
    ./system.nix
    ./fonts.nix
    ./brew.nix
    { services.tailscale.enable = true; }
  ];
}
