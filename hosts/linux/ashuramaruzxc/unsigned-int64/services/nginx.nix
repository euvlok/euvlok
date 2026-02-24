{
  lib,
  config,
  pkgs,
  ...
}:
{
  security.pam.services.nginx.setEnvironment = false;
  systemd.services.nginx.serviceConfig = {
    SupplementaryGroups = [ "shadow" ];
  };
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
      credentialsFile = config.sops.secrets.cloudflare-api_token.path;
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
      proxy_cookie_path / "/; secure; HttpOnly; SameSite=strict";
    '';
    virtualHosts."_" = {
      default = true;
      listen = [
        { addr = "80"; }
        { addr = "[::]:80"; }
        {
          addr = "443";
          ssl = true;
        }
        {
          addr = "[::]:443";
          ssl = true;
        }
      ];
      extraConfig = ''
        ssl_reject_handshake on;
        return 444;
      '';
    };
    virtualHosts."static.fumoposting.com" = {
      serverName = "static.fumoposting.com";
      forceSSL = true;
      enableACME = true;
      basicAuthFile = config.sops.secrets.minecraft.path;
      locations."/" = {
        root = "/var/lib/www/minecraft/static";
        extraConfig = ''
          autoindex on;
        '';
      };
    };
  };
  users.groups.minecraft = {
    gid = config.users.users.minecraft.uid;
    members = [
      "ashuramaru"
      "fumono"
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
      "fumono"
      "docker"
      "nginx"
    ];
    openssh.authorizedKeys.keys = lib.flatten [
      config.users.users.ashuramaru.openssh.authorizedKeys.keys
      config.users.users.fumono.openssh.authorizedKeys.keys
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILzAn2WaivFLvPqaB77TvUaH87Cw1VJcIb0VDsPRpcXh sokol@PekPC"
    ];
    shell = pkgs.zsh;
  };
}
