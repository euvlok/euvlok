{
  config,
  lib,
  ...
}:
{
  options.euvlok.home.devenv.enable = lib.options.mkEnableOption "devenv" // {
    default = true;
  };

  config = lib.modules.mkIf config.euvlok.home.devenv.enable {
    programs.devenv.enable = true;
  };
}
