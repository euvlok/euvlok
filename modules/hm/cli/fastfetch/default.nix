{ lib, config, ... }:
{
  options.hm.fastfetch.enable = lib.mkEnableOption "Fastfetch";

  config = lib.mkIf config.hm.fastfetch.enable {
    programs.fastfetch.enable = true;
    programs.fastfetch.settings = builtins.fromJSON (builtins.readFile ./settings.json);
  };
}
