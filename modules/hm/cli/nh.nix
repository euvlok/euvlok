{ lib, config, ... }:
{
  options.euvlok.home.nh.enable = lib.options.mkEnableOption "Nh";

  config = lib.modules.mkIf config.euvlok.home.nh.enable {
    programs.nh.enable = true;
    programs.nh.flake = "/etc/nixos";
  };
}
