{ lib, config, ... }:
{
  options.hm.fastfetch.enable = lib.options.mkEnableOption "Fastfetch";

  config = lib.modules.mkIf config.hm.fastfetch.enable {
    programs.fastfetch.enable = true;
    programs.fastfetch.settings = builtins.fromJSON (builtins.readFile ./settings.json);
  };
}
