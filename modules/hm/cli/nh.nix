{ lib, config, ... }:
{
  options.hm.nh.enable = lib.options.mkEnableOption "Nh";

  config = lib.modules.mkIf config.hm.nh.enable {
    programs.nh.enable = true;
    programs.nh.flake = "/etc/nixos";
  };
}
