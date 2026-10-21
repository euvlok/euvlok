{ config, lib, ... }:
let
  cfg = config.services.forgejo;
  privateDomain = "git.tenjin.com";
  proxyLocations = {
    "/" = {
      proxyPass = cfg.settings.server.LOCAL_ROOT_URL;
      proxyWebsockets = true;
      recommendedProxySettings = true;
      extraConfig = ''
        proxy_request_buffering off;
        proxy_read_timeout 600s;
        proxy_send_timeout 600s;
      '';
    };
    # Forgejo serves uploaded avatars before its normal sign-in middleware.
    "~ ^/(avatars|repo-avatars)/" = {
      proxyPass = lib.removeSuffix "/" cfg.settings.server.LOCAL_ROOT_URL;
      recommendedProxySettings = true;
      extraConfig = ''
        auth_request /_forgejo_auth;
        proxy_hide_header Cache-Control;
      '';
    };
    "= /_forgejo_auth" = {
      proxyPass = "${cfg.settings.server.LOCAL_ROOT_URL}user/settings";
      recommendedProxySettings = true;
      extraConfig = ''
        internal;
        proxy_method GET;
        proxy_pass_request_body off;
        proxy_set_header Content-Length "";
        proxy_intercept_errors on;
        error_page 301 302 303 307 308 = @forgejo_login_required;
      '';
    };
    "@forgejo_login_required".return = "403";
    # These endpoints are exclusively for the local Prometheus and runner.
    "= /metrics".return = "404";
    "^~ /metrics/".return = "404";
    "^~ /api/actions/".return = "404";
    "^~ /api/internal/".return = "404";
  };
in
{
  # HTTP scope preserves shared security headers; empty map values add no header.
  services.nginx.commonHttpConfig = ''
    map "$host:$uri" $forgejo_avatar_cache_control {
      default "";
      "~^(${lib.escapeRegex cfg.settings.server.DOMAIN}|${lib.escapeRegex privateDomain}):/(avatars|repo-avatars)/" "private, no-store";
    }
    add_header Cache-Control $forgejo_avatar_cache_control always;
  '';

  services.nginx.virtualHosts = {
    ${cfg.settings.server.DOMAIN} = {
      forceSSL = true;
      enableACME = true;
      # Public DNS points here; validate over HTTP without DNS API credentials.
      acmeRoot = "/var/lib/acme/acme-challenge";
      # Stream large Git/LFS uploads; Forgejo performs authentication itself.
      extraConfig = "client_max_body_size 0;";
      locations = proxyLocations;
    };
    ${privateDomain} = {
      forceSSL = true;
      sslCertificate = "/etc/ssl/self/tenjin.com/tenjin.com.crt";
      sslCertificateKey = "/etc/ssl/self/tenjin.com/tenjin.com.key";
      sslTrustedCertificate = "/etc/ssl/self/tenjin.com/ca.crt";
      # Private DNS alone does not stop requests with a forged Host/SNI name.
      extraConfig = ''
        client_max_body_size 0;
        allow 127.0.0.1;
        allow ::1;
        allow 172.16.31.0/24;
        allow fd17:216b:31bc::/48;
        allow 100.64.0.0/10;
        allow fd7a:115c:a1e0::/48;
        deny all;
      '';
      locations = proxyLocations;
    };
  };
  networking.hosts = {
    "172.16.31.1" = [ privateDomain ];
    "fd17:216b:31bc:1::1" = [ privateDomain ];
  };
  services.unbound.settings.server.local-data = [
    ''"${privateDomain}. 10800 IN A 172.16.31.1"''
    ''"${privateDomain}. 10800 IN AAAA fd17:216b:31bc:1::1"''
  ];
}
