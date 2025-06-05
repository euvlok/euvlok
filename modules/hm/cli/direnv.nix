{ lib, config, ... }:
{
  options.hm.direnv.enable = lib.mkEnableOption "Direnv" // {
    default = true;
  };

  config = lib.mkIf config.hm.direnv.enable {
    programs.direnv.enable = true;
    programs.direnv.nix-direnv.enable = true;
  };
}
