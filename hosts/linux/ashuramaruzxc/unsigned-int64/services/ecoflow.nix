{ config, ... }:
{
  sops.secrets.ecolinker_env.restartUnits = [ "ecolinker.service" ];

  services.ecolinker = {
    enable = true;
    environmentFiles = [ config.sops.secrets.ecolinker_env.path ];
    environment = {
      TZ = config.time.timeZone;
      ECOFLOW_URL = "https://api-e.ecoflow.com";
      ECOFLOW_MQTT_ENABLED = "false";
      SERVER_LISTEN = "127.0.0.1";
      SERVER_PORT = "9981";
      PROMETHEUS_ENABLED = "true";
      PROMETHEUS_LISTEN = "127.0.0.1";
      PROMETHEUS_PORT = "9981";
      DB_POSTGRES_HOST = "/run/postgresql";
      DB_POSTGRES_PORT = toString config.services.postgresql.settings.port;
      DB_POSTGRES_NAME = "ecolinker";
      DB_POSTGRES_USER = "ecolinker";
      DB_POSTGRES_TZ = config.time.timeZone;
      DB_POSTGRES_PASSWORD = "unused-local-socket";
    };
  };

  systemd.services.ecolinker = {
    after = [
      "network-online.target"
      "postgresql.service"
    ];
    wants = [ "network-online.target" ];
    requires = [ "postgresql.service" ];
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };

  environment.systemPackages = [ config.services.ecolinker.package ];
}
