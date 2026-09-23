{ lib, ... }:
{
  services.postgresql = {
    enable = true;
    enableJIT = true;
    enableTCPIP = true;
    settings = {
      # Leave four physical cores available for Immich's API and the other
      # services while allowing parallel vector queries and index maintenance.
      max_worker_processes = 16;
      max_parallel_workers = 12;
      max_parallel_workers_per_gather = 4;
      max_parallel_maintenance_workers = 4;
    };
    ensureDatabases = [
      "vaultwarden"
      "grafana"
      "cvat"
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
        name = "cvat";
        ensureDBOwnership = true;
      }
    ];
    authentication = lib.modules.mkOverride 10 ''
      #type database DBuser origin-address auth-method
      local all       all     trust
      host  all      all     127.0.0.1/32   trust
      host all       all     ::1/128        trust
    '';
  };

  services.postgresqlBackup = {
    enable = true;
    databases = [
      "nextcloud"
      "vaultwarden"
      "grafana"
      "immich"
    ];
    location = "/var/lib/backup/postgresql";
  };
}
