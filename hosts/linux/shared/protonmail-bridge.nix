# All credit goes to "https://github.com/nix-community/home-manager/issues/3019#issuecomment-2241833501"
# !@nick4f42
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
        description = "Whether to enable the Bridge.";
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
        description = "The log level";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    systemd.user.services.protonmail-bridge = {
      Unit = {
        Description = "Protonmail Bridge";
        After = [ "network.target" ];
      };

      Service = {
        Restart = "always";
        ExecStart = "${cfg.package}/bin/protonmail-bridge --noninteractive --log-level ${cfg.logLevel}";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
