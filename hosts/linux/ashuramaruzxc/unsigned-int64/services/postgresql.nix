{ lib, ... }:
{
  services.postgresql = {
    enable = true;
    enableJIT = true;
    enableTCPIP = true;
    ensureDatabases = [
      "vaultwarden"
      "grafana"
      "cvat"
      "attic"
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
      {
        name = "atticd";
        ensureDBOwnership = true;
      }
    ];
    authentication = lib.mkOverride 10 ''
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
    ];
    location = "/var/lib/backup/postgresql";
  };
}
