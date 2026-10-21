{
  lib,
  config,
  pkgs,
  ...
}:
let
  datasourceUid = "dnscrypt-prometheus";
  dashboardDatasource = {
    type = "prometheus";
    uid = datasourceUid;
  };
  selector = ''{job="dnscrypt-router",instance=~"$instance"}'';
  metric = name: "dnscrypt_proxy_${name}${selector}";
  rate = name: "rate(${metric name}[$__rate_interval])";
  panel = id: title: unit: expressions: {
    inherit id title;
    type = "timeseries";
    datasource = dashboardDatasource;
    gridPos = {
      x = ((id - 1) - (builtins.div (id - 1) 2) * 2) * 12;
      y = (builtins.div (id - 1) 2) * 8;
      w = 12;
      h = 8;
    };
    fieldConfig.defaults = {
      inherit unit;
      min = 0;
    };
    options = {
      legend = {
        displayMode = "list";
        placement = "bottom";
      };
      tooltip.mode = "multi";
    };
    targets = builtins.genList (i: {
      refId = builtins.elemAt [ "A" "B" "C" ] i;
      inherit (builtins.elemAt expressions i) expr;
      legendFormat = (builtins.elemAt expressions i).legend;
    }) (builtins.length expressions);
  };
  dashboard = {
    uid = "dnscrypt-router";
    title = "DNSCrypt router";
    description = "Native dnscrypt-proxy Prometheus metrics, scraped over WireGuard. Response-time averages and cache ratio are cumulative since process startup.";
    schemaVersion = 39;
    version = 1;
    editable = false;
    tags = [
      "dnscrypt"
      "router"
    ];
    timezone = "browser";
    refresh = "30s";
    time = {
      from = "now-6h";
      to = "now";
    };
    templating.list = [
      {
        name = "instance";
        label = "Router";
        type = "query";
        datasource = dashboardDatasource;
        query = ''label_values(up{job="dnscrypt-router"}, instance)'';
        refresh = 1;
        current = {
          text = "172.16.31.2:8080";
          value = "172.16.31.2:8080";
        };
      }
    ];
    panels = [
      (panel 1 "Scrape status (1 = up)" "short" [
        {
          expr = "up${selector}";
          legend = "Scrape status";
        }
      ])
      (panel 2 "DNSCrypt uptime" "s" [
        {
          expr = metric "uptime_seconds";
          legend = "Uptime";
        }
      ])
      (panel 3 "Query rate" "reqps" [
        {
          expr = rate "queries_total";
          legend = "Queries";
        }
      ])
      (panel 4 "Cache hit ratio since startup" "percentunit" [
        {
          expr = metric "cache_hit_ratio";
          legend = "Cache hit ratio";
        }
      ])
      (panel 5 "Cache activity" "reqps" [
        {
          expr = rate "cache_hits_total";
          legend = "Hits";
        }
        {
          expr = rate "cache_misses_total";
          legend = "Misses";
        }
      ])
      (panel 6 "Blocked query rate" "reqps" [
        {
          expr = rate "blocked_queries_total";
          legend = "Blocked";
        }
      ])
      (panel 7 "Query rate by upstream" "reqps" [
        {
          expr = rate "server_queries_total";
          legend = "{{server}}";
        }
      ])
      (panel 8 "Query rate by record type" "reqps" [
        {
          expr = rate "query_type_total";
          legend = "{{type}}";
        }
      ])
      (panel 9 "Average response time since startup" "ms" [
        {
          expr = metric "response_time_average_ms";
          legend = "All queries";
        }
      ])
      (panel 10 "Average upstream response time since startup" "ms" [
        {
          expr = metric "server_response_time_average_ms";
          legend = "{{server}}";
        }
      ])
    ];
  };
in
{
  sops.secrets.grafana_pgsql = {
    mode = "0640";
    owner = config.users.users.grafana.name;
    group = config.users.users.grafana.group;
  };
  services.grafana = {
    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "DNSCrypt Prometheus";
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
          name = "dnscrypt-router";
          folder = "DNS";
          type = "file";
          options.path = pkgs.writeTextDir "dnscrypt-router.json" (builtins.toJSON dashboard);
        }
      ];
    };
    enable = true;
    settings = {
      server = {
        enable_gzip = true;
        enforce_domain = true;
        protocol = "http";
        domain = "metrics.tenjin.com";
        http_addr = "127.0.0.1";
        http_port = 2301;
        serve_from_sub_path = true;
        # root_url = "%(protocol)s://%(domain)s:%(http_port)s/";
        root_url = "https://metrics.tenjin.com/grafana/";
      };
      database = {
        type2 = "postgres";
        name = "grafana";
        user = "grafana";
        password = "$__file{${config.sops.secrets.grafana_pgsql.path}}";
        ssl_mode = "disable";
        host = "127.0.0.1:5432";
        log_queries = true;
      };
      smtp = {
        enable = true;
        host = "sinope.uberspace.de";
        user = "no-reply@cloud.tenjin-dk.com";
        password = "$__file{${config.sops.secrets.mail.path}}";
        from_address = "no-reply@cloud.tenjin-dk.com";
        from_name = "grafana notifyer";
        ehlo_identity = "metrics.tenjin-dk.com";
      };
      user = {
        verify_email_enabled = true;
        default_theme = true;
        default_language = "en_us";
      };
      security.secret_key = "SW2YcwTIb9zpOOhoPsMm";
    };
    declarativePlugins = lib.attrsets.attrValues {
      # These datasource plugins are distributed separately in Grafana 13.
      inherit (pkgs.grafanaPlugins) grafana-piechart-panel prometheus loki;
    };
  };
  # HTTPS queries to metrics.tenjin.com use the same private CA as nginx.
  systemd.services.grafana = {
    environment.SSL_CERT_FILE = "/run/grafana/ca-certificates.crt";
    serviceConfig.LoadCredential = [ "tenjin-ca:/etc/ssl/self/tenjin.com/ca.crt" ];
    preStart = ''
      ${pkgs.coreutils}/bin/cat ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt \
        "$CREDENTIALS_DIRECTORY/tenjin-ca" > "$RUNTIME_DIRECTORY/ca-certificates.crt"
    '';
  };
  systemd.services.prometheus = {
    after = [
      "nginx.service"
      "unbound.service"
    ];
    requires = [
      "nginx.service"
      "unbound.service"
    ];
  };
  systemd.services.loki = {
    after = [
      "nginx.service"
      "unbound.service"
    ];
    requires = [
      "nginx.service"
      "unbound.service"
    ];
  };
  services.prometheus = {
    enable = true;
    # Keep enough history for the EcoFlow dashboard's 30-day energy query.
    retentionTime = "35d";
    listenAddress = "127.0.0.1";
    webExternalUrl = "/prometheus";
    port = 9000;
    exporters = {
      node = {
        enable = true;
        enabledCollectors = [
          "systemd"
          "logind"
          "mountstats"
          "ethtool"
          "sysctl"
        ];
        port = 9100;
      };
      wireguard = {
        enable = true;
        withRemoteIp = true;
        singleSubnetPerField = true;
        port = 9101;
      };
      redis = {
        enable = true;
        port = 9102;
      };
    };
    scrapeConfigs = [
      # Router metrics use WireGuard with source 172.16.31.1.
      {
        job_name = "dnscrypt-router";
        scheme = "http";
        metrics_path = "/metrics";
        scrape_interval = "30s";
        scrape_timeout = "10s";
        static_configs = [
          {
            targets = [ "172.16.31.2:8080" ];
            labels = {
              device = "rt-be88u";
            };
          }
        ];
      }
      {
        job_name = "unsigned-int64";
        static_configs = [
          { targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ]; }
        ];
      }
      {
        job_name = "wireguard";
        static_configs = [
          { targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.wireguard.port}" ]; }
        ];
      }
      {
        job_name = "redis";
        static_configs = [
          { targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.redis.port}" ]; }
        ];
      }
      {
        job_name = "grafana";
        metrics_path = "/grafana/metrics";
        static_configs = [
          { targets = [ "127.0.0.1:${toString config.services.grafana.settings.server.http_port}" ]; }
        ];
      }
      {
        job_name = "prometheus";
        metrics_path = "/prometheus/metrics";
        static_configs = [ { targets = [ "127.0.0.1:${toString config.services.prometheus.port}" ]; } ];
      }
      {
        job_name = "ecoflow";
        metrics_path = "/metrics";
        scrape_interval = "30s";
        static_configs = [
          { targets = [ "127.0.0.1:${config.services.ecolinker.environment.PROMETHEUS_PORT}" ]; }
        ];
      }
    ];
  };
  services.loki = {
    enable = true;
    configuration = {
      server.http_listen_port = 3100;
      auth_enabled = false;

      ingester = {
        lifecycler = {
          address = "127.0.0.1";
          ring = {
            kvstore = {
              store = "inmemory";
            };
            replication_factor = 1;
          };
        };
        chunk_idle_period = "1h";
        max_chunk_age = "1h";
        chunk_target_size = 999999;
        chunk_retain_period = "30s";
      };

      schema_config = {
        configs = [
          {
            from = "2023-12-31";
            object_store = "filesystem";
            store = "tsdb";
            schema = "v13";
            index = {
              prefix = "loki_ops_index_";
              period = "24h";
            };
          }
        ];
      };

      storage_config = {
        boltdb_shipper = {
          active_index_directory = "/var/lib/loki/boltdb-shipper-active";
          cache_location = "/var/lib/loki/boltdb-shipper-cache";
          cache_ttl = "24h";
        };
        tsdb_shipper = {
          active_index_directory = "/var/lib/loki/tsdb-index";
          cache_location = "/var/lib/loki/tsdb-cache";
        };
        filesystem = {
          directory = "/var/lib/loki/chunks";
        };
      };

      limits_config = {
        reject_old_samples = true;
        reject_old_samples_max_age = "168h";
      };

      table_manager = {
        retention_deletes_enabled = false;
        retention_period = "0s";
      };

      compactor = {
        working_directory = "/var/lib/loki";
        compactor_ring = {
          kvstore = {
            store = "inmemory";
          };
        };
      };
    };
  };
  services.fluent-bit = {
    enable = true;
    settings = {
      pipeline = {
        inputs = [
          {
            name = "systemd";
            tag = "systemd.*";
            db = "/var/lib/fluent-bit/systemd.db";
            read_from_tail = true;
          }
        ];
        outputs = [
          {
            name = "loki";
            match = "systemd.*";
            host = "127.0.0.1";
            port = config.services.loki.configuration.server.http_listen_port;
            labels = "job=systemd-journal,host=unsigned-int64";
            label_keys = "$_SYSTEMD_UNIT";
          }
        ];
      };
    };
  };
  systemd.tmpfiles.settings.fluent-bit."/var/lib/fluent-bit".d = {
    mode = "0750";
    user = "root";
    group = "root";
  };

  services.nginx.virtualHosts = {
    "${config.services.grafana.settings.server.domain}" = {
      forceSSL = true;
      sslCertificate = "/etc/ssl/self/tenjin.com/tenjin.com.crt";
      sslCertificateKey = "/etc/ssl/self/tenjin.com/tenjin.com.key";
      sslTrustedCertificate = "/etc/ssl/self/tenjin.com/ca.crt";
      locations = {
        "/grafana/" = {
          proxyPass = "http://${toString config.services.grafana.settings.server.http_addr}:${toString config.services.grafana.settings.server.http_port}";
          proxyWebsockets = true;
          recommendedProxySettings = true;
        };
        "/grafana/api/live/" = {
          proxyPass = "http://${toString config.services.grafana.settings.server.http_addr}:${toString config.services.grafana.settings.server.http_port}";
          proxyWebsockets = true;
          recommendedProxySettings = true;
        };
        "/prometheus" = {
          proxyPass = "http://127.0.0.1:${toString config.services.prometheus.port}";
          proxyWebsockets = true;
        };
      };
    };
  };
}
