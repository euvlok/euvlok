{ lib, ... }:
{
  services = {
    forgejo.settings.packages.ENABLED = lib.mkForce true;

    nginx.virtualHosts."games.tenjin.com" = {
      forceSSL = true;
      sslCertificate = "/etc/ssl/self/tenjin.com/tenjin.com.crt";
      sslCertificateKey = "/etc/ssl/self/tenjin.com/tenjin.com.key";
      sslTrustedCertificate = "/etc/ssl/self/tenjin.com/ca.crt";
      extraConfig = ''
        allow 127.0.0.1;
        allow ::1;
        allow 172.16.31.0/24;
        allow fd17:216b:31bc::/48;
        allow 100.64.0.0/10;
        allow fd7a:115c:a1e0::/48;
        deny all;
      '';
      locations = {
        "= /" = {
          return = ''200 "WIP"'';
          extraConfig = "default_type text/plain;";
        };
        "= /dolx".return = "301 /dolx/";
        "/dolx/" = {
          proxyPass = "http://127.0.0.1:18080/";
          recommendedProxySettings = true;
        };
        "= /tsukihime".return = "308 /tsukihime/";
        "/tsukihime/" = {
          # Tsukihime's Caddy server expects the prefix used by its Vite build.
          proxyPass = "http://127.0.0.1:18081";
          recommendedProxySettings = true;
        };
        "= /umineko".return = "308 /umineko/";
        "/umineko/" = {
          # Umineko resolves assets relative to the page; its server expects /.
          proxyPass = "http://127.0.0.1:18082/";
          recommendedProxySettings = true;
        };
        "/".return = "404";
      };
    };
    unbound.settings.server.local-data = [
      ''"games.tenjin.com. 10800 IN A 172.16.31.1"''
      ''"games.tenjin.com. 10800 IN AAAA fd17:216b:31bc:1::1"''
    ];
  };
  networking.hosts = {
    "172.16.31.1" = [ "games.tenjin.com" ];
    "fd17:216b:31bc:1::1" = [ "games.tenjin.com" ];
  };
}
