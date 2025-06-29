{ pkgs, lib, ... }:
{
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  boot = {
    tmp.useTmpfs = true;
    loader.raspberryPi.firmwarePackage = pkgs.linuxAndFirmware.v6_6_31.raspberrypifw;
    kernelPackages = pkgs.linuxAndFirmware.v6_6_31.linuxPackages_rpi5;
  };
  nixpkgs.overlays = lib.mkAfter [
    (self: super: {
      # This is used in (modulesPath + "/hardware/all-firmware.nix") when at least
      # enableRedistributableFirmware is enabled
      # I know no easier way to override this package
      inherit (pkgs.linuxAndFirmware.v6_6_31) raspberrypiWirelessFirmware;
      # Some derivations want to use it as an input,
      # e.g. raspberrypi-dtbs, omxplayer, sd-image-* modules
      inherit (pkgs.linuxAndFirmware.v6_6_31) raspberrypifw;
    })
  ];

  console.earlySetup = true;
  console.font = lib.mkDefault "${pkgs.terminus_font}/share/consolefonts/ter-u16n.psf.gz";

  system.fsPackages = [ pkgs.sshfs ];
  environment.systemPackages = [ pkgs.cifs-utils ];
}
