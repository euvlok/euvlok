{ lib, config, ... }:
{
  options.hm.nh.enable = lib.mkEnableOption "Nh";

  config = lib.mkIf config.hm.nh.enable {
    programs.nh.enable = true;
    programs.nh.flake = "/etc/nixos";
  };
}
