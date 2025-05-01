{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.services.protonmail-bridge;
in
{
  options = {
    services.protonmail-bridge = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to enable the ProtonMail Bridge.";
      };
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.protonmail-bridge;
        defaultText = lib.literalExpression "pkgs.protonmail-bridge";
        description = "The protonmail-bridge package to use.";
      };
      logLevel = lib.mkOption {
        type = lib.types.enum [
          "panic"
          "fatal"
          "error"
          "warn"
          "info"
          "debug"
        ];
        default = "info";
        description = "Log verbosity level for ProtonMail Bridge.";
      };
    };
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    # LaunchAgent configuration for macOS
    launchd.user.agents."protonmail-bridge" = {
      command = "${lib.getExe cfg.package} --noninteractive --log-level ${cfg.logLevel}";
      serviceConfig = {
        RunAtLoad = true;
        KeepAlive = true;
        EnvironmentVariables = {
          PATH = lib.makeBinPath [
            cfg.package
            pkgs.coreutils
          ];
        };
      };
    };
  };
}
