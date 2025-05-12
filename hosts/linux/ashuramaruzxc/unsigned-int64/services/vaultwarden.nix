{
  config,
  pkgs,
  ...
}:
{
  sops.secrets.vaultwarden-env = {
    mode = "770";
    owner = config.users.users.vaultwarden.name;
    group = config.users.users.vaultwarden.group;
  };

  sops.secrets.vault = {
    mode = "0640";
    owner = config.users.users.nginx.name;
    group = config.users.users.nginx.group;
  };

  services.vaultwarden = {
    enable = true;
    package = pkgs.vaultwarden-postgresql;
    environmentFile = config.sops.secrets.vaultwarden-env.path;
    dbBackend = "postgresql";
    config = {
      domain = "https://bitwarden.tenjin-dk.com";
      rocketAddress = "127.0.0.1";
      rocketPort = "8080";
      rocketLog = "critical";

      websocketEnabled = true;
      websocketAddress = "127.0.0.1";
      websocketPort = "3012";
      enableDbWal = true;

      signupsAllowed = false;
      signupsVerify = true;
      signupsDomainsWhitelist = "fumoposting.com, tenjin-dk.com, riseup.net, meanrin.cat, waifu.club";

      smtpHost = "antila.uberspace.de";
      smtpSecurity = "starttls";
      smtpPort = 587;
      smtpAuthMechanism = "Login";
      smtpUsername = "no-reply@cloud.tenjin-dk.com";
      smtpFrom = "no-reply@cloud.tenjin-dk.com";
      smtpFromName = "Admin of bitwarden.tenjin-dk.com";
    };
  };
  services.nginx.upstreams."vaultwarden-default" = {
    extraConfig = ''
      keepalive 2;
    '';
    servers = {
      "127.0.0.1:8080" = {
        backup = false;
      };
    };
  };
  services.nginx.virtualHosts."bitwarden.tenjin-dk.com" = {
    serverName = "bitwarden.tenjin-dk.com";
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://vaultwarden-default";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_hide_header X-Frame-Options;
      '';
    };
    locations."/admin" = {
      basicAuthFile = config.sops.secrets.vault.path;
      proxyPass = "http://vaultwarden-default";
      proxyWebsockets = true;
    };
  };
}
