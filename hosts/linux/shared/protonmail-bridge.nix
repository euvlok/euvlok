{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.services.protonmail-bridge;

  # Create a wrapped protonmail-bridge package
  wrappedBridge =
    pkgs.runCommand "protonmail-bridge"
      {
        bridge = pkgs.protonmail-bridge;
        nativeBuildInputs = [ pkgs.makeWrapper ];
      }
      ''
        mkdir -p $out/bin
        makeWrapper $bridge/bin/protonmail-bridge $out/bin/protonmail-bridge \
            --set PATH ${lib.strings.makeBinPath [ pkgs.gnome-keyring ]}
      '';
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
        description = "The log level.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ wrappedBridge ];

    systemd.user.services.protonmail-bridge = {
      Unit = {
        Description = "ProtonMail Bridge";
        After = [ "network.target" ];
      };
      Service = {
        Restart = "always";
        ExecStart = "${wrappedBridge}/bin/protonmail-bridge --noninteractive --log-level ${cfg.logLevel}";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
