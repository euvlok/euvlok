{
  config,
  pkgs,
  ...
}:
let
  datasourceUid = "ecoflow-prometheus";
  ecolinkerPort = "7660";
  source = pkgs.fetchurl {
    url = "https://grafana.com/api/dashboards/17812/revisions/9/download";
    hash = "sha256-69RuK4QEqGOvUU/5ms/TB72zlsPqhiRufHLicOn6Vsw=";
    name = "ecoflow-17812-revision-9.json";
  };
  selector = ''job="ecoflow",device="$device"'';
  metric = name: ''{__name__=~"ecolinker_${name}",${selector}}'';
  bms = field: metric "bms_bmsStatus[._]${field}";
  ems = field: metric "bms_emsStatus[._]${field}";
  inv = field: metric "inv[._]${field}";
  mppt = field: metric "mppt[._]${field}";
  soc = "${bms "f32ShowSoc"} or on(device) ${ems "f32LcdShowSoc"} or on(device) ${metric "pd[._]soc"}";
  solarPower = "(${mppt "inVol"} / 1000) * on(device) (${mppt "inAmp"} / 1000)";
  solarEnergy = range: "increase(${metric "pd[._]chgSunPower"}[${range}])";
  queries = {
    "46".A = ''max(up{job="ecoflow"}) or vector(0)'';
    "23".A = inv "inputWatts";
    "26".A = inv "acInVol";
    "29".A = inv "acInAmp";
    "33".A = ems "chgRemainTime";
    "37".A = bms "fullCap";
    "31".A = "abs(${bms "amp"})";
    "28".A = bms "vol";
    "35".A = bms "minCellVol";
    "36".A = bms "maxCellVol";
    "21".A = soc;
    "24".A = inv "outputWatts";
    "27".A = inv "invOutVol";
    "30".A = inv "invOutAmp";
    "32".A = ems "dsgRemainTime";
    "34".A = bms "remainCap";
    "42".A = bms "cycles";
    "38".A = inv "outTemp";
    "40".A = bms "minCellTemp";
    "39".A = bms "maxCellTemp";
    "41".A = bms "amp";
    "8".A = soc;
    "4" = {
      A = inv "inputWatts";
      B = inv "outputWatts";
    };
    "10" = {
      C = "abs(${ems "chgRemainTime"})";
      D = "abs(${ems "dsgRemainTime"})";
    };
    "2" = {
      A = "${inv "acInVol"} > 0";
      E = "${inv "invOutVol"} > 0";
      B = bms "vol";
    };
    "6" = {
      A = inv "outTemp";
      B = metric "pd[._]carTemp";
      C = bms "temp";
      D = bms "maxCellTemp";
      E = bms "minCellTemp";
      F = bms "maxMosTemp";
      G = bms "minMosTemp";
    };
    "18" = {
      A = inv "acInAmp";
      E = inv "invOutAmp";
      B = "abs(${bms "amp"})";
    };
    "44" = {
      A = metric "pd[._]usb1Watts";
      C = metric "pd[._]typec1Watts";
    };
    "45" = {
      A = bms "vol";
      C = bms "minCellVol";
      B = bms "maxCellVol";
    };
    "55" = {
      A = mppt "inWatts";
      C = solarPower;
    };
    "61".A = "${mppt "inVol"} / 1000";
    "63".A = "${mppt "inAmp"} / 1000";
    "65".A = "${bms "amp"} / 1000";
    "67" = {
      A = solarEnergy "$__range";
      B = solarEnergy "24h";
      E = solarEnergy "7d";
      G = solarEnergy "30d";
    };
    "69" = {
      A = "(${bms "vol"} / 1000) * on(device) (${bms "amp"} / 1000)";
      B = solarPower;
    };
    "48".A = ''time() - ecolinker_collector_last_invocation{${selector},kind="device_parameters"}'';
  };
  changes = pkgs.writeText "ecoflow-dashboard-changes.json" (
    builtins.toJSON {
      inherit queries datasourceUid;
      deviceQuery = ''label_values({job="ecoflow",__name__=~"ecolinker_.+",device!=""}, device)'';
    }
  );
  dashboard = pkgs.runCommand "ecoflow-dashboards" { nativeBuildInputs = [ pkgs.jq ]; } ''
    mkdir -p "$out"
    jq --slurpfile changes ${changes} '
      $changes[0] as $c
      | walk(
          if type == "object" then
            if .type? == "prometheus" and has("uid") then
              .uid = $c.datasourceUid
            elif has("targets") then
              (.id | tostring) as $id
              | if $id == "67" then .targets |= map(select(.refId | IN("A", "B", "E", "G"))) else . end
              | .targets |= map(
                  .expr = ($c.queries[$id][.refId] // error("Unmapped EcoFlow target: " + $id + "/" + .refId))
                  | del(.exemplar)
                )
            else . end
          else . end
        )
      | del(.__inputs, .__elements, .__requires)
      | .id = null
      | .uid = "ecoflow-delta-2"
      | .title = "EcoFlow DELTA 2"
      | .description = "DELTA 2 telemetry"
      | .editable = false
      | .version = 2
      | .timezone = "browser"
      | .tags += ["ecolinker"]
      | .links += [{title: "Original EcoFlow dashboard", type: "link", url: "https://grafana.com/grafana/dashboards/17812-ecoflow/", targetBlank: true}]
      | .templating.list |= map(
          if .name == "device" then
            .current = {}
            | .options = []
            | .definition = $c.deviceQuery
            | .query.query = $c.deviceQuery
          else . end
        )
      | walk(
          if type == "object" and has("gridPos") then
            if .id == 46 then
              .description = "Exporter availability. This does not confirm that the device is online or that its last REST request succeeded."
              | .fieldConfig.defaults.mappings[0].options["0"].text = "Exporter down"
              | .fieldConfig.defaults.mappings[0].options["1"].text = "Exporter up"
            elif .id == 65 then
              .title = "Battery current balance"
            elif .id == 67 then
              .title = "Solar energy"
              | .description = "Solar charge from the device cumulative Wh counter, with counter resets handled."
              | .targets |= map(.legendFormat = ({A: "Selected range", B: "24 hours", E: "7 days", G: "30 days"}[.refId]))
            elif .id == 69 then
              .title = "Battery / solar power"
            elif .id == 59 then
              .title = "REST polling"
            elif .id == 48 then
              .title = "Time since last REST poll attempt"
              | .description = "Collector scheduling activity; failed API requests also count as attempts."
              | .fieldConfig.defaults.unit = "s"
              | .targets[0].legendFormat = "{{device}} poll age"
            else . end
          else . end
        )
    ' ${source} > "$out/ecoflow-delta-2.json"
  '';
in
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
      SERVER_PORT = ecolinkerPort;
      PROMETHEUS_ENABLED = "true";
      PROMETHEUS_LISTEN = "127.0.0.1";
      PROMETHEUS_PORT = ecolinkerPort;
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
      "postgresql.target"
    ];
    wants = [ "network-online.target" ];
    requires = [ "postgresql.target" ];
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };

  environment.systemPackages = [ config.services.ecolinker.package ];

  services.grafana.provision = {
    datasources.settings.datasources = [
      {
        name = "EcoFlow Prometheus";
        uid = datasourceUid;
        type = "prometheus";
        access = "proxy";
        url = "https://${config.services.grafana.settings.server.domain}/prometheus";
        jsonData.timeInterval = "30s";
        editable = false;
      }
    ];
    dashboards.settings.providers = [
      {
        name = "ecoflow";
        folder = "Energy";
        type = "file";
        options.path = dashboard;
      }
    ];
  };
}
