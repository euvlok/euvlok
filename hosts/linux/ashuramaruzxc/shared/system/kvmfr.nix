{ lib, config, ... }:
let
  cfg = config.virtualisation.kvmfr;
in
{
  options.virtualisation.kvmfr = {
    enable = lib.options.mkEnableOption "Kvmfr";

    shm = {
      enable = lib.options.mkEnableOption "shm";

      size = lib.options.mkOption {
        type = lib.types.ints.positive;
        default = 128;
        description = "Size of the shared memory device in megabytes.";
      };
      user = lib.options.mkOption {
        type = lib.types.nonEmptyStr;
        default = "root";
        description = "Owner of the shared memory device.";
      };
      group = lib.options.mkOption {
        type = lib.types.nonEmptyStr;
        default = "root";
        description = "Group of the shared memory device.";
      };
      mode = lib.options.mkOption {
        type = lib.types.strMatching "[0-7]{4}";
        default = "0600";
        description = "Mode of the shared memory device.";
      };
    };
  };

  config = lib.modules.mkIf cfg.enable {
    boot.extraModulePackages = builtins.attrValues { inherit (config.boot.kernelPackages) kvmfr; };
    boot.initrd.kernelModules = [ "kvmfr" ];
    boot.kernelParams = lib.lists.optional cfg.shm.enable "kvmfr.static_size_mb=${toString cfg.shm.size}";
    services.udev.extraRules = lib.modules.mkIf cfg.shm.enable ''
      SUBSYSTEM=="kvmfr", OWNER="${cfg.shm.user}", GROUP="${cfg.shm.group}", MODE="${cfg.shm.mode}"
    '';
  };
}
