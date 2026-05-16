{ lib, config, ... }:
{
  options.hm.fzf.enable = lib.options.mkEnableOption "FZF" // {
    default = true;
  };

  config = lib.modules.mkIf config.hm.fzf.enable { programs.fzf.enable = true; };
}
