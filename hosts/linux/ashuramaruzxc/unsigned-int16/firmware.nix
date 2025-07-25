{ lib, pkgs, ... }:
{
  nixpkgs.overlays = lib.mkAfter [
    (self: super: {
      inherit (pkgs.linuxAndFirmware.v6_12_25)
        raspberrypiWirelessFirmware
        raspberrypifw
        ;
    })
  ];
}
