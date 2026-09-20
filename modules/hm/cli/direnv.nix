{ lib, config, ... }:
{
  options.euvlok.home.direnv.enable = lib.options.mkEnableOption "Direnv" // {
    default = true;
  };

  config = lib.modules.mkIf config.euvlok.home.direnv.enable {
    programs.direnv.enable = true;
    programs.direnv.nix-direnv.enable = true;
  };
}
