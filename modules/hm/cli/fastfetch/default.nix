{ lib, config, ... }:
{
  options.euvlok.home.fastfetch.enable = lib.options.mkEnableOption "Fastfetch";

  config = lib.modules.mkIf config.euvlok.home.fastfetch.enable {
    programs.fastfetch.enable = true;
    programs.fastfetch.settings = lib.trivial.importJSON ./settings.json;
  };
}
