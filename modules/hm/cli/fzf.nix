{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.euvlok.home.fzf.enable = lib.options.mkEnableOption "FZF" // {
    default = true;
  };

  config = lib.modules.mkIf config.euvlok.home.fzf.enable {
    programs.fzf = {
      enable = true;
      package = pkgs.unstable.fzf;
    };
  };
}
