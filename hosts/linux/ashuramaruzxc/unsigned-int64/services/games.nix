{ lib, ... }:
{
  services = {
    forgejo.settings.packages.ENABLED = lib.modules.mkForce true;

    nginx.virtualHosts."games.tenjin.com" = {
      sslCertificate = "/etc/ssl/self/tenjin.com/tenjin.com.crt";
      sslCertificateKey = "/etc/ssl/self/tenjin.com/tenjin.com.key";
      sslTrustedCertificate = "/etc/ssl/self/tenjin.com/ca.crt";
      extraConfig = ''
        allow 127.0.0.1;
        allow ::1;
        allow 172.16.31.0/24;
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
        };
        "= /tsukihime".return = "308 /tsukihime/";
        "/tsukihime/" = {
          # Tsukihime's Caddy server expects the prefix used by its Vite build.
          proxyPass = "http://127.0.0.1:18081";
        };
        "= /tsukire".return = "308 /tsukire/";
        "/tsukire/" = {
          proxyPass = "http://127.0.0.1:18083";
        };
        "= /umineko".return = "308 /umineko/";
        "/umineko/" = {
          # Umineko resolves assets relative to the page; its server expects /.
          proxyPass = "http://127.0.0.1:18082/";
        };
        "/".return = "404";
      };
    };
  };
  services.unbound.settings.server.local-data = [
    ''"games.tenjin.com. 10800 IN A 172.16.31.1"''
  ];
}
