{ lib, config, ... }:
{
  options.hm.bash.enable = lib.mkEnableOption "Bash" // {
    default = true;
  };

  config = lib.mkIf config.hm.bash.enable {
    programs.bash = {
      enable = true;
      enableVteIntegration = true;
    };
  };
}
