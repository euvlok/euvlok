{ lib, ... }:
{
  services.postgresql = {
    enable = true;
    enableJIT = true;
    enableTCPIP = true;

    ensureDatabases = [
      "vaultwarden"
      "grafana"
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
    # Restore a dump with: zstd -dc DATABASE.sql.zstd | psql postgres
    compression = "zstd";
    compressionLevel = 3;
    databases = [
      "nextcloud"
      "vaultwarden"
      "grafana"
      "immich"
    ];
    location = "/var/lib/backup/postgresql";
  };
}
