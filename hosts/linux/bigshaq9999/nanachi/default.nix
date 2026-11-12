{
  homeModule,
  sharedModule,
}:
_: {
  imports = [
    sharedModule
    ./configuration.nix
    homeModule
  ];

  euvlok.nixos = {
    boot.systemd-boot.enable = true;
    plasma.enable = true;
  };

  catppuccin = {
    enable = true;
    flavor = "frappe";
    accent = "blue";
  };
}
