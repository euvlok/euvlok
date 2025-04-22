{
  lib,
  pkgs,
  config,
  ...
}:

let
  cfg = config.virtualisation.kvmfr;
in
{
  options.virtualisation.kvmfr = {
    enable = lib.mkEnableOption "Kvmfr";

    shm = {
      enable = lib.mkEnableOption "shm";

      size = lib.mkOption {
        type = lib.types.int;
        default = "128";
        description = "Size of the shared memory device in megabytes.";
      };
      user = lib.mkOption {
        type = lib.types.str;
        default = "root";
        description = "Owner of the shared memory device.";
      };
      group = lib.mkOption {
        type = lib.types.str;
        default = "root";
        description = "Group of the shared memory device.";
      };
      mode = lib.mkOption {
        type = lib.types.str;
        default = "0600";
        description = "Mode of the shared memory device.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    boot.extraModulePackages = builtins.attrValues { inherit (config.boot.kernelPackages) kvmfr; };
    boot.initrd.kernelModules = [ "kvmfr" ];
    boot.kernelParams = [ "kvmfr.static_size_mb=${toString cfg.shm.size}" ];
    services.udev.extraRules = ''
      SUBSYSTEM=="kvmfr", OWNER="${cfg.shm.user}", GROUP="${cfg.shm.group}", MODE="${cfg.shm.mode}"
    '';
  };
}
