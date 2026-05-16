{ lib, config, ... }:
{
  options.hm.zellij.enable = lib.options.mkEnableOption "Zellij";

  config = lib.modules.mkIf config.hm.zellij.enable {
    programs.zellij.enable = true;
  };
}
