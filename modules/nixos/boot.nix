{ lib, config, ... }:
let
  cfg = config.nixos.boot;
in
{
  options.nixos.boot.systemd-boot.enable = lib.mkEnableOption "systemd-boot with EFI" // {
    default = false;
  };

  config = lib.mkIf cfg.systemd-boot.enable {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
  };
}
