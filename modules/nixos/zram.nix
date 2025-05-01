{ lib, config, ... }:
let
  cfg = config.nixos.zram;
in
{
  options.zram.enable = lib.mkEnableOption "Enable zram swap";
  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      zramSwap.enable = true;
    })
    (lib.mkIf cfg.algorithm {
      zramSwap.algorithm = lib.mkDefault "zstd";
    })
    (lib.mkIf cfg.optimizations.enable {
      boot.kernel.sysctl = {
        "vm.swappiness" = 180;
        "vm.watermark_boost_factor" = 0;
        "vm.watermark_scale_factor" = 125;
        "vm.page-cluster" = 0;
      };
      zramSwap.priority = 15;
    })
  ];
}
