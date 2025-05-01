{ lib, config, ... }:
{
  options.nixos.zram.enable = lib.mkEnableOption "Enable zram swap";

  config = lib.mkIf config.nixos.zram.enable {
    zramSwap.enable = true;
    boot.kernel.sysctl = {
      "vm.swappiness" = 180;
      "vm.watermark_boost_factor" = 0;
      "vm.watermark_scale_factor" = 125;
      "vm.page-cluster" = 0;
    };
    zramSwap.priority = 15;
  };
}
