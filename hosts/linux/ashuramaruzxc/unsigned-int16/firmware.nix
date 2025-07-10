{ lib, config, ... }:
{
  nixpkgs.overlays = lib.mkAfter [
    (self: super: {
      # https://github.com/nvmd/nixos-raspberrypi-demo/blob/a9031b6d2d68d0fc43c39b85905b0e924f60dd7e/flake.nix#L291C13-L301C15
      inherit (config.kernelPackages) raspberrypiWirelessFirmware raspberrypifw;
    })
  ];
}
