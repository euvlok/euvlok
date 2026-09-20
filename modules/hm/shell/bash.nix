{ lib, config, ... }:
{
  options.euvlok.home.bash.enable = lib.options.mkEnableOption "Bash" // {
    default = true;
  };

  config = lib.modules.mkIf config.euvlok.home.bash.enable {
    programs.bash = {
      enable = true;
      enableVteIntegration = true;
    };
  };
}
