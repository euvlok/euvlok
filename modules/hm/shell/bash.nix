{
  pkgs,
  lib,
  config,
  osConfig,
  ...
}:
{
  options.hm.bash.enable = lib.mkEnableOption "Bash" // {
    default = true;
  };

  config = lib.mkIf config.hm.bash.enable {
    programs.bash = {
      enable = true;
      enableVteIntegration = true;
      #! not everyone needs copilot
      initExtra = lib.optionalString (lib.any (pkg: pkg == pkgs.github-copilot-cli) (
        osConfig.environment.systemPackages
      )) ''eval "$(github-copilot-cli alias -- "$0")"'';
    };
  };
}
