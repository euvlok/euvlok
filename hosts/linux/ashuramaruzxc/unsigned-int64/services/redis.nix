{ config, ... }:
{
  sops.secrets.ecoflow_exporter = {
    mode = "0640";
    owner = config.users.users.redis-ecoflow_exporter.name;
    group = config.users.users.redis-ecoflow_exporter.group;
  };
  services.redis = {
    vmOverCommit = true;
    servers = {
      "ecoflow_exporter" = {
        enable = true;
        bind = "172.16.31.1";
        port = 6373;
        appendOnly = true;
        save = [
          [
            3600
            1
          ]
        ];
        openFirewall = true;
        requirePassFile = config.sops.secrets.ecoflow_exporter.path;
      };
    };
  };
}
