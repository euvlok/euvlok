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
  options.services.protonmail-bridge = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable the ProtonMail Bridge service.";
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
      description = "Log verbosity level for the ProtonMail Bridge service.";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.mkIf pkgs.stdenv.isLinux (
        let
          wrappedBridge =
            pkgs.runCommand "protonmail-bridge-wrapped"
              {
                nativeBuildInputs = [ pkgs.makeWrapper ];
              }
              ''
                mkdir -p $out/bin
                makeWrapper ${lib.getExe cfg.package} $out/bin/protonmail-bridge \
                  --set PATH ${lib.makeBinPath [ pkgs.gnome-keyring ]}
              '';
        in
        {
          home.packages = [ wrappedBridge ];
          systemd.user.services.protonmail-bridge = {
            Unit = {
              Description = "ProtonMail Bridge";
              After = [ "network.target" ];
            };
            Service = {
              Restart = "on-failure";
              RestartSec = "5s";
              ExecStart = "${wrappedBridge}/bin/protonmail-bridge --noninteractive --log-level ${cfg.logLevel}";
            };
            Install = {
              WantedBy = [ "default.target" ];
            };
          };
        }
      ))
      (lib.mkIf pkgs.stdenv.isDarwin {
        home.packages = [ cfg.package ];
        launchd.agents.protonmail-bridge = {
          config = {
            ProgramArguments = [
              "${lib.getExe cfg.package}"
              "--noninteractive"
              "--log-level"
              cfg.logLevel
            ];
            RunAtLoad = true;
            KeepAlive = true;
            EnvironmentVariables = {
              PATH = lib.makeBinPath [ pkgs.coreutils ];
            };
          };
        };
      })
    ]
  );
}
