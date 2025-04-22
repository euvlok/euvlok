{ config, ... }:
{
  sops.secrets.mail = {
    mode = "0640";
    owner = config.users.users.mail.name;
    group = config.users.users.mail.group;
  };
  users.groups.mail = {
    gid = config.users.users.mail.uid;
    members = [
      "nextcloud"
      "vaultwarden"
      "grafana"
    ];
  };
  users.users.mail = {
    uid = 4322;
    isSystemUser = true;
    group = "mail";
    extraGroups = [
      "nextcloud"
      "vaultwarden"
      "grafana"
    ];
  };
  programs.msmtp = {
    enable = true;
    accounts = {
      default = {
        auth = true;
        tls = true;
        port = 587;
        host = "antila.uberspace.de";
        from = "no-reply@cloud.tenjin-dk.com";
        user = "no-reply@cloud.tenjin-dk.com";
        passwordeval = "cat ${toString config.sops.secrets.mail.path}";
      };
    };
  };
}
