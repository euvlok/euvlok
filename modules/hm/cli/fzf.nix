{ lib, config, ... }:
{
  options.hm.fzf.enable = lib.mkEnableOption "FZF" // {
    default = true;
  };

  config = lib.mkIf config.hm.fzf.enable { programs.fzf.enable = true; };
}
