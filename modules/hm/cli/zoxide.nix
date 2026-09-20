{ lib, config, ... }:
{
  options.euvlok.home.zoxide.enable = lib.options.mkEnableOption "Zoxide" // {
    default = true;
  };

  config = lib.modules.mkIf config.euvlok.home.zoxide.enable { programs.zoxide.enable = true; };
}
