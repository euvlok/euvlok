{
  lib,
  config,
  pkgs,
  ...
}:
{
  sops.secrets.transmission_env = {
    mode = "0640";
    owner = config.users.users.transmission.name;
    group = config.users.users.transmission.group;
  };
  services.transmission = {
    enable = true;
    openPeerPorts = true;
    downloadDirPermissions = "775";
    home = "/var/lib/transmission/public";
    settings = {
      utp-enabled = true; # to not forget
      watch-dir-enabled = true;
      watch-dir = "${config.services.transmission.home}/watch-dir";
      incomplete-dir-enabled = true;
      incomplete-dir = "${config.services.transmission.home}/incomplete";
      download-dir = "${config.services.transmission.home}/Downloads";
      rpc-bind-address = "0.0.0.0";
      rpc-port = 18765;
      rpc-whitelist-enabled = true;
      rpc-whitelist = "172.16.31.*";
      rpc-host-whitelist-enabled = true;
      rpc-host-whitelist = "*";
      dht-enabled = false;
      pex-enabled = false;
      lpd-enabled = false;
    };
    webHome = pkgs.flood-for-transmission;
  };
  services.radarr = {
    enable = true;
    user = "jellyfin";
    group = "jellyfin";
  };
  services.sonarr = {
    enable = true;
    user = "jellyfin";
    group = "jellyfin";
  };
  services.lidarr = {
    enable = true;
    user = "jellyfin";
    group = "jellyfin";
  };
  services.readarr = {
    enable = true;
    user = "jellyfin";
    group = "jellyfin";
  };
  services.bazarr = {
    enable = true;
    listenPort = 8763;
    user = "jellyfin";
    group = "jellyfin";
  };
  services.prowlarr.enable = true;
  users.groups.transmission = {
    gid = 70;
    members = [
      "jellyfin"
      "transmission"
    ];
  };
  users.users.transmission = {
    homeMode = "0770";
    openssh.authorizedKeys.keys = lib.flatten [
      config.users.users.ashuramaru.openssh.authorizedKeys.keys
      config.users.users.fumono.openssh.authorizedKeys.keys
    ];
    group = "${config.users.groups.transmission.name}";
    extraGroups = [
      "jellyfin"
      "transmission"
    ];
    uid = 70;
    shell = pkgs.zsh;
  };
  services.nginx.virtualHosts = {
    "public.tenjin.com" = {
      forceSSL = true;
      sslCertificate = "/etc/ssl/self/tenjin.com/tenjin.com.crt";
      sslCertificateKey = "/etc/ssl/self/tenjin.com/tenjin.com.key";
      sslTrustedCertificate = "/etc/ssl/self/tenjin.com/ca.crt";
      locations."/" = {
        proxyPass = "http://172.16.31.1:18765";
      };
    };
    "private.tenjin.com" = {
      forceSSL = true;
      sslCertificate = "/etc/ssl/self/tenjin.com/tenjin.com.crt";
      sslCertificateKey = "/etc/ssl/self/tenjin.com/tenjin.com.key";
      sslTrustedCertificate = "/etc/ssl/self/tenjin.com/ca.crt";
      locations."/" = {
        proxyPass = "http://172.16.31.1:9091";
      };
    };
    "lib.tenjin.com" = {
      forceSSL = true;
      sslCertificate = "/etc/ssl/self/tenjin.com/tenjin.com.crt";
      sslCertificateKey = "/etc/ssl/self/tenjin.com/tenjin.com.key";
      sslTrustedCertificate = "/etc/ssl/self/tenjin.com/ca.crt";
      locations."/radarr" = {
        proxyPass = "http://172.16.31.1:7878/radarr";
      };
      locations."/radarr/api" = {
        proxyPass = "http://172.16.31.1:7878";
      };
      locations."/lidarr" = {
        proxyPass = "http://172.16.31.1:8686/lidarr";
      };
      locations."/lidarr/api" = {
        proxyPass = "http://172.16.31.1:8686";
      };
      locations."/readarr" = {
        proxyPass = "http://172.16.31.1:8787/readarr";
      };
      locations."/readarr/api" = {
        proxyPass = "http://172.16.31.1:8787";
      };
      locations."/bazarr" = {
        proxyPass = "http://172.16.31.1:8763/bazarr";
      };
      locations."/bazarr/api" = {
        proxyPass = "http://172.16.31.1:8763";
      };
      locations."/sonarr" = {
        proxyPass = "http://172.16.31.1:8989/sonarr";
      };
      locations."/sonarr/api" = {
        proxyPass = "http://172.16.31.1:8989";
      };
      locations."/prowlarr" = {
        proxyPass = "http://172.16.31.1:9696/prowlarr";
      };
      locations."/prowlarr/api" = {
        proxyPass = "http://172.16.31.1:9696";
      };
    };
  };
  virtualisation.oci-containers.containers."transmission_private" = {
    image = "haugene/transmission-openvpn";
    environmentFiles = [ "${config.sops.secrets.transmission_env.path}" ];
    environment = {
      "OPENVPN_PROVIDER" = "custom";
      "OPENVPN_CONFIG" = "de-214.protonvpn.udp";
      "LOCAL_NETWORK" = "172.16.31.0/24";

      "TRANSMISSION_WEB_UI" = "flood-for-transmission";
      "TRANSMISSION_RPC_PORT" = "9091";
      "TRANSMISSION_RPC_USERNAME" = "ashuramaru";
      "TRANSMISSION_DOWNLOAD_DIR" = "/data/Downloads";
      "TRANSMISSION_INCOMPLETE_DIR_ENABLED" = "true";
      "TRANSMISSION_INCOMPLETE_DIR" = "/data/incomplete";

      "TRANSMISSION_SPEED_LIMIT_UP_ENABLED" = "true";
      "TRANSMISSION_SPEED_LIMIT_UP" = "5000";
      "TRANSMISSION_SPEED_LIMIT_DOWN_ENABLED" = "true";
      "TRANSMISSION_SPEED_LIMIT_DOWN" = "5000";
      "TRANSMISSION_ALT_SPEED_UP" = "5000";
      "TRANSMISSION_ALT_SPEED_DOWN" = "5000";

      "TZ" = "Europe/Berlin";
      "PUID" = "70";
      "PGID" = "70";
    };
    volumes = [
      "/var/lib/transmission/private:/data:rw"
      "/var/lib/transmission/private/config:/config:rw"
      "/var/lib/transmission/private/protonvpn:/etc/openvpn/custom"
    ];
    ports = [ "172.16.31.1:9091:9091/tcp" ];
    log-driver = "journald";
    extraOptions = [
      "--device=/dev/net/tun"
      "--cap-add=NET_ADMIN,mknod"
      "--network-alias=transmission-ovpn"
      "--network=transmission_openvpn-default"

      # Mullvad specific no longer needed
      # "--sysctl=net.ipv6.conf.all.disable_ipv6=0"
    ];
  };
  systemd.services."podman-transmission_private" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
    };
    after = [ "podman-network-transmission_openvpn-default.service" ];
    requires = [ "podman-network-transmission_openvpn-default.service" ];
    partOf = [ "podman-compose-transmission_openvpn-root.target" ];
    wantedBy = [ "podman-compose-transmission_openvpn-root.target" ];
  };
  systemd.services."podman-network-transmission_openvpn-default" = {
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "${lib.getExe' pkgs.podman "podman"} network rm -f transmission_openvpn-default";
    };
    script = ''
      podman network inspect transmission_openvpn-default || podman network create transmission_openvpn-default --opt isolate=true
    '';
    partOf = [ "podman-compose-transmission_openvpn-root.target" ];
    wantedBy = [ "podman-compose-transmission_openvpn-root.target" ];
  };
  systemd.targets."podman-compose-transmission_openvpn-root" = {
    unitConfig = {
      Description = "Root target generated by compose2nix.";
    };
    wantedBy = [ "multi-user.target" ];
  };
}
