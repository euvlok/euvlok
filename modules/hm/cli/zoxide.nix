{ lib, config, ... }:
{
  options.hm.zoxide.enable = lib.mkEnableOption "Zoxide" // {
    default = true;
  };

  config = lib.mkIf config.hm.zoxide.enable { programs.zoxide.enable = true; };
}
