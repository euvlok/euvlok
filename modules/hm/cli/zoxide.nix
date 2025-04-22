{ lib, config, ... }:
{
  options.hm.zoxide.enable = lib.mkOption {
    default = true;
    description = "Enable Zoxide";
    type = lib.types.bool;
  };

  config = lib.mkIf config.hm.zoxide.enable { programs.zoxide.enable = true; };
}
