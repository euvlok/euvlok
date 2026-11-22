{
  config,
  lib,
  pkgs,
  ...
}:
{
  security.pam.services.nginx.setEnvironment = false;
  systemd.services.nginx.serviceConfig = {
    SupplementaryGroups = [ "shadow" ];
  };
  imports = [
    {
      options.services.nginx.virtualHosts = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule (
            { config, ... }:
            {
              forceSSL = lib.mkForce false;
              onlySSL = !config.rejectSSL;
              quic = true;
              listen =
                map
                  (addr: {
                    inherit addr;
                    port = 443;
                    ssl = true;
                  })
                  [
                    "0.0.0.0"
                    "[::]"
                  ];
              reuseport = config.default;
            }
          )
        );
      };
    }
  ];

  # Advertise HTTP/3 to first-time clients of the private DNS zone.
  services.unbound.settings.server.local-data = map (
    name: ''"${name}. 10800 IN HTTPS 1 . alpn=h3,h2"''
  ) (lib.filter (lib.hasSuffix ".tenjin.com") (lib.attrNames config.services.nginx.virtualHosts));

  sops.secrets.minecraft = {
    mode = "0640";
    owner = config.users.users.nginx.name;
    group = config.users.users.nginx.group;
  };
  sops.secrets.cloudflare-api_token = {
    mode = "0640";
    owner = config.users.users.acme.name;
    group = config.users.users.acme.group;
  };
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "ashuramaru@tenjin-dk.com";
      dnsResolver = "1.1.1.1:53";
      dnsProvider = "cloudflare";
      # This secret contains CLOUDFLARE_DNS_API_TOKEN=<token>, not a raw token.
      environmentFile = config.sops.secrets.cloudflare-api_token.path;
    };
  };
  services.nginx = {
    enable = true;
    additionalModules = [ pkgs.nginxModules.pam ];

    recommendedUwsgiSettings = true;
    recommendedTlsSettings = true;
    recommendedProxySettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedBrotliSettings = true;

    sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";

    commonHttpConfig = ''
      client_body_buffer_size 512k;
      map $scheme $hsts_header {
          https   "max-age=31536000; includeSubdomains; preload";
      }
      add_header Strict-Transport-Security $hsts_header;
      add_header 'Referrer-Policy' 'origin-when-cross-origin';
      add_header X-Content-Type-Options nosniff;
    '';
    virtualHosts."_" = {
      default = true;
      rejectSSL = true;
      extraConfig = "return 444;";
    };
  };
  users.groups.minecraft = {
    gid = config.users.users.minecraft.uid;
    members = [
      "ashuramaru"
      "minecraft"
      "nginx"
    ];
  };
  users.groups.nginx.members = [ "minecraft" ];
  users.users.nginx.extraGroups = [ "minecraft" ];
  users.users.minecraft = {
    uid = 5333;
    isNormalUser = true;
    home = "/var/lib/minecraft";
    initialHashedPassword = "";
    extraGroups = [
      "minecraft"
      "ashuramaru"
      "nginx"
    ];
    openssh.authorizedKeys.keys = config.users.users.ashuramaru.openssh.authorizedKeys.keys;
    shell = pkgs.zsh;
  };
}
