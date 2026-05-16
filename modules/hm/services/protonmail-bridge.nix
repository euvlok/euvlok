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
    enable = lib.options.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable the ProtonMail Bridge service.";
    };

    package = lib.options.mkOption {
      type = lib.types.package;
      default = pkgs.protonmail-bridge;
      defaultText = lib.options.literalExpression "pkgs.protonmail-bridge";
      description = "The protonmail-bridge package to use.";
    };

    logLevel = lib.options.mkOption {
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

  config = lib.modules.mkIf cfg.enable (
    lib.modules.mkMerge [
      (lib.modules.mkIf pkgs.stdenvNoCC.isLinux (
        let
          wrappedBridge =
            pkgs.runCommand "protonmail-bridge-wrapped"
              {
                nativeBuildInputs = [ pkgs.makeWrapper ];
              }
              ''
                mkdir -p $out/bin
                makeWrapper ${lib.meta.getExe cfg.package} $out/bin/protonmail-bridge \
                  --set PATH ${lib.strings.makeBinPath [ pkgs.gnome-keyring ]}
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
      (lib.modules.mkIf pkgs.stdenv.isDarwin {
        home.packages = [ cfg.package ];
        launchd.agents.protonmail-bridge = {
          config = {
            ProgramArguments = [
              "${lib.meta.getExe cfg.package}"
              "--noninteractive"
              "--log-level"
              cfg.logLevel
            ];
            RunAtLoad = true;
            KeepAlive = true;
            EnvironmentVariables = {
              PATH = lib.strings.makeBinPath [ pkgs.coreutils ];
            };
          };
        };
      })
    ]
  );
}
