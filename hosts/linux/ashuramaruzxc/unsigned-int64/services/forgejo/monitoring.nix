{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.forgejo;
  tokenFile = "${cfg.customDir}/conf/metrics_token";
  datasourceUid = "forgejo-prometheus";
  panel = id: title: unit: targets: {
    inherit id title targets;
    type = "timeseries";
    datasource = {
      type = "prometheus";
      uid = datasourceUid;
    };
    gridPos = {
      x = (lib.mod (id - 1) 2) * 12;
      y = (builtins.div (id - 1) 2) * 8;
      w = 12;
      h = 8;
    };
    fieldConfig.defaults = {
      inherit unit;
      min = 0;
    };
    options.legend = {
      displayMode = "list";
      placement = "bottom";
    };
  };
  dashboard = {
    uid = "forgejo";
    title = "Forgejo";
    description = "Forgejo application and local service health on unsigned-int64. Forgejo 15 retains the gitea_ metric prefix.";
    schemaVersion = 39;
    version = 1;
    editable = false;
    tags = [ "forgejo" ];
    timezone = "browser";
    refresh = "30s";
    time = {
      from = "now-6h";
      to = "now";
    };
    panels = [
      (panel 1 "Forgejo scrape status (1 = up)" "short" [
        {
          refId = "A";
          expr = ''up{job="forgejo"}'';
          legendFormat = "Forgejo";
        }
      ])
      (panel 2 "Local services (1 = active)" "short" [
        {
          refId = "A";
          expr = ''node_systemd_unit_state{job="unsigned-int64",name=~"forgejo.service|forgejo-runner-local.service|postgresql.service|redis-forgejo.service",state="active"}'';
          legendFormat = "{{name}}";
        }
      ])
      (panel 3 "Repositories and users" "short" [
        {
          refId = "A";
          expr = ''gitea_repositories{job="forgejo"}'';
          legendFormat = "Repositories";
        }
        {
          refId = "B";
          expr = ''gitea_users{job="forgejo"}'';
          legendFormat = "Users";
        }
      ])
      (panel 4 "Issues" "short" [
        {
          refId = "A";
          expr = ''gitea_issues_open{job="forgejo"}'';
          legendFormat = "Open";
        }
        {
          refId = "B";
          expr = ''gitea_issues_closed{job="forgejo"}'';
          legendFormat = "Closed";
        }
      ])
      (panel 5 "Forgejo resident memory" "bytes" [
        {
          refId = "A";
          expr = ''process_resident_memory_bytes{job="forgejo"}'';
          legendFormat = "RSS";
        }
      ])
      (panel 6 "Forgejo CPU usage" "cores" [
        {
          refId = "A";
          expr = ''rate(process_cpu_seconds_total{job="forgejo"}[$__rate_interval])'';
          legendFormat = "CPU cores";
        }
      ])
      (panel 7 "Forgejo goroutines" "short" [
        {
          refId = "A";
          expr = ''go_goroutines{job="forgejo"}'';
          legendFormat = "Goroutines";
        }
      ])
      (panel 8 "Forgejo uptime" "s" [
        {
          refId = "A";
          expr = ''time() - process_start_time_seconds{job="forgejo"}'';
          legendFormat = "Uptime";
        }
      ])
    ];
  };
in
{
  services.forgejo = {
    settings.metrics = {
      ENABLED = true;
      ENABLE_ISSUE_BY_LABEL = false;
      ENABLE_ISSUE_BY_REPOSITORY = false;
    };
    secrets.metrics.TOKEN = tokenFile;
  };
  systemd.services.forgejo-secrets.script = lib.mkAfter ''
    if [ ! -s '${tokenFile}' ]; then
      ${pkgs.openssl}/bin/openssl rand -hex 32 > '${tokenFile}.tmp'
      mv '${tokenFile}.tmp' '${tokenFile}'
    fi
  '';
  systemd.services.prometheus = {
    after = [ "forgejo-secrets.service" ];
    requires = [ "forgejo-secrets.service" ];
    serviceConfig.LoadCredential = [ "forgejo-metrics:${tokenFile}" ];
    preStart = ''
      ${config.services.prometheus.package.cli}/bin/promtool check config /etc/prometheus/prometheus.yaml
    '';
  };
  # Credential paths exist only in the service namespace; preStart validates them.
  services.prometheus.checkConfig = "syntax-only";
  services.prometheus.enableReload = true;
  services.prometheus.scrapeConfigs = [
    {
      job_name = "forgejo";
      scheme = "http";
      metrics_path = "/metrics";
      scrape_interval = "30s";
      bearer_token_file = "/run/credentials/prometheus.service/forgejo-metrics";
      static_configs = [
        { targets = [ "127.0.0.1:${toString cfg.settings.server.HTTP_PORT}" ]; }
      ];
    }
  ];
  services.grafana.provision = {
    datasources.settings.datasources = [
      {
        name = "Forgejo Prometheus";
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
        name = "forgejo";
        folder = "Forgejo";
        type = "file";
        options.path = pkgs.writeTextDir "forgejo.json" (builtins.toJSON dashboard);
      }
    ];
  };
}
