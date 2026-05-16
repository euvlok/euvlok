{ lib, config, ... }:
{
  options.hm.zoxide.enable = lib.options.mkEnableOption "Zoxide" // {
    default = true;
  };

  config = lib.modules.mkIf config.hm.zoxide.enable { programs.zoxide.enable = true; };
}
