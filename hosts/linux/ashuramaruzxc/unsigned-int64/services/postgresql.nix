{ config, lib, ... }:
{
  services.postgresql = {
    enable = true;
    enableJIT = true;
    enableTCPIP = true;
    settings = {
      # Leave four physical cores available for Immich's API and the other
      # services while allowing parallel vector queries and index maintenance
      max_worker_processes = 16;
      max_parallel_workers = 12;
      max_parallel_workers_per_gather = 4;
      max_parallel_maintenance_workers = 4;
    };

    ensureDatabases = [
      "vaultwarden"
      "grafana"
      "ecolinker"
      "freshrss"
    ];
    ensureUsers = [
      {
        name = "superuser";
        ensureClauses = {
          superuser = true;
          createrole = true;
          createdb = true;
        };
      }
      {
        name = "vaultwarden";
        ensureDBOwnership = true;
      }
      {
        name = "grafana";
        ensureDBOwnership = true;
      }
      {
        name = "ecolinker";
        ensureDBOwnership = true;
      }
      {
        name = "freshrss";
        ensureDBOwnership = true;
      }
    ];
    authentication = lib.modules.mkOverride 10 ''
      #type database DBuser origin-address auth-method
      ${lib.optionalString config.services.forgejo.enable ''
        local forgejo   forgejo peer
        local forgejo   postgres peer
        local forgejo   all     reject
        host  forgejo   all     0.0.0.0/0 reject
        host  forgejo   all     ::/0 reject
        local all       forgejo reject
        host  all       forgejo 0.0.0.0/0 reject
        host  all       forgejo ::/0 reject
      ''}
      local all       all     trust
      host  all      all     127.0.0.1/32   trust
      host all       all     ::1/128        trust
    '';
  };

  services.postgresqlBackup = {
    enable = true;
    # Restore a dump with: zstd -dc DATABASE.sql.zstd | psql postgres
    compression = "zstd";
    compressionLevel = 3;
    databases = [
      "nextcloud"
      "vaultwarden"
      "grafana"
      "immich"
      "ecolinker"
    ];
    location = "/var/lib/backup/postgresql";
  };
}
