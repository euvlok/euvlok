{
  config,
  pkgs,
  ...
}:
{
  sops.secrets.grafana_pgsql = {
    mode = "0640";
    owner = config.users.users.grafana.name;
    group = config.users.users.grafana.group;
  };
  services.grafana = {
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
        host = "antila.uberspace.de";
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
    };
    declarativePlugins = builtins.attrValues { inherit (pkgs.grafanaPlugins) grafana-piechart-panel; };
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
        metrics_path = "/metrics";
        static_configs = [ { targets = [ "127.0.0.1:${toString config.services.prometheus.port}" ]; } ];
      }
      {
        job_name = "ecoflow";
        metrics_path = "/metrics";
        static_configs = [ { targets = [ "172.16.31.1:9981" ]; } ];
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
  services.promtail = {
    enable = true;
    configuration = {
      server = {
        http_listen_port = 3031;
        grpc_listen_port = 0;
      };
      positions = {
        filename = "/tmp/positions.yaml";
      };
      clients = [
        {
          url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}/loki/api/v1/push";
        }
      ];
      scrape_configs = [
        {
          job_name = "journal";
          journal = {
            max_age = "24h";
            labels = {
              job = "systemd-journal";
              host = "unsigned-int64";
            };
          };
          relabel_configs = [
            {
              source_labels = [ "__journal__systemd_unit" ];
              target_label = "unit";
            }
          ];
        }
      ];
    };
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
