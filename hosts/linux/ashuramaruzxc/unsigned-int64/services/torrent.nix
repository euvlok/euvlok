{
  lib,
  config,
  pkgs,
  ...
}:
let
  protonPortForwardScript = pkgs.writeTextFile {
    name = "protonvpn-update-port";
    executable = true;
    text = ''
      #!/usr/bin/env bash

      set -euo pipefail

      # shellcheck source=/dev/null
      . /etc/transmission/environment-variables.sh

      TRANSMISSION_PASSWD_FILE=/config/transmission-credentials.txt

      transmission_username=$(head -1 "''${TRANSMISSION_PASSWD_FILE}")
      transmission_passwd=$(tail -1 "''${TRANSMISSION_PASSWD_FILE}")
      transmission_settings_file=''${TRANSMISSION_HOME}/settings.json

      box_out() {
          local message="$*"
          printf '\033[36m╭─%s─╮\n\033[36m│ \033[34m%s\033[36m │\n\033[36m╰─%s─╯\033[0;39m\n' \
              "''${message//?/─}" "$message" "''${message//?/─}"
      }

      open_port() {
          timeout 5 natpmpc -a 1 0 udp 60 >/dev/null 2>&1 &&
              timeout 5 natpmpc -a 1 0 tcp 60
      }

      remote() {
          if test -n "$myauth"; then
              transmission-remote "$TRANSMISSION_RPC_PORT" --auth "$myauth" --json "$@"
          else
              transmission-remote "$TRANSMISSION_RPC_PORT" --json "$@"
          fi
      }

      bind_transmission() {
          local new_port=$forwarded_port
          local current_port

          if test "$(jq -r '.["rpc-authentication-required"]' "$transmission_settings_file")" == "true"; then
              myauth="$transmission_username:$transmission_passwd"
          else
              myauth=""
          fi

          get_peer_port() {
              remote --session-info | jq -r '
                if (.arguments? | type) == "object" then
                  .arguments["peer-port"]
                elif (.result? | type) == "object" then
                  (.result.peer_port // .result["peer-port"])
                else
                  empty
                end
              '
          }

          echo "Waiting for Transmission RPC"
          until remote --list >/dev/null 2>&1; do sleep 5; done

          current_port=$(get_peer_port)
          if test "$new_port" -ne "$current_port"; then
              echo "Setting Transmission peer port to $new_port"
              until remote --port "$new_port" >/dev/null 2>&1; do sleep 5; done
          fi

          if test "$(get_peer_port)" != "$new_port"; then
              echo "Transmission did not adopt port $new_port"
              return 1
          fi

          echo "Transmission is listening on port $new_port"
      }

      for dependency in jq natpmpc timeout; do
          if ! command -v "$dependency" >/dev/null; then
              echo "$dependency is required for ProtonVPN port forwarding"
              exit 1
          fi
      done

      box_out "ProtonVPN Port Forwarding"

      while true; do
          date
          forwarded_port="$(open_port | sed -nr '1,//s/Mapped public port ([0-9]{4,5}) protocol.*/\1/p')"
          if test "''${forwarded_port:-0}" -gt 1024; then
              if bind_transmission; then
                  box_out "The Forwarded Port is: $forwarded_port"
              else
                  box_out "The Forwarded Port is: Unavailable"
              fi
          else
              box_out "No port returned from natpmpc"
          fi
          sleep 45
      done
    '';
  };
in
{
  sops.secrets.transmission_env = {
    mode = "0640";
    owner = config.users.users.transmission.name;
    group = config.users.users.transmission.group;
  };
  services.transmission = {
    enable = true;
    openPeerPorts = false;
    downloadDirPermissions = "775";
    home = "/var/lib/transmission/public";
    settings = {
      utp-enabled = true; # to not forget
      watch-dir-enabled = true;
      watch-dir = "${config.services.transmission.home}/watch-dir";
      incomplete-dir-enabled = true;
      incomplete-dir = "${config.services.transmission.home}/incomplete";
      download-dir = "${config.services.transmission.home}/Downloads";
      rpc-bind-address = "172.16.31.1";
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
  systemd.services.transmission = {
    after = [ "wg-quick-wireguard0.service" ];
    wants = [ "wg-quick-wireguard0.service" ];
  };

  # The public peer port is deliberately exposed only on the WAN interface.
  networking.firewall.interfaces.enp5s0 = {
    allowedTCPPorts = [ 51413 ];
    allowedUDPPorts = [ 51413 ];
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
    openssh.authorizedKeys.keys = lib.lists.concatLists [
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
      "${protonPortForwardScript}:/etc/openvpn/custom/update-port.sh:ro"
    ];
    ports = [ "172.16.31.1:9091:9091/tcp" ];
    log-driver = "journald";
    extraOptions = [
      "--device=/dev/net/tun"
      "--cap-drop=NET_BIND_SERVICE"
      "--cap-add=NET_ADMIN,MKNOD"
      "--security-opt=no-new-privileges"
      "--network-alias=transmission-ovpn"
      "--network=transmission_openvpn-default"

      # Mullvad specific no longer needed
      # "--sysctl=net.ipv6.conf.all.disable_ipv6=0"
    ];
  };
  systemd.services."podman-transmission_private" = {
    serviceConfig = {
      Restart = lib.modules.mkOverride 500 "always";
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
      ExecStop = "${lib.meta.getExe' pkgs.podman "podman"} network rm -f transmission_openvpn-default";
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
