_: {
  networking = {
    hostName = "unsigned-int64";
    interfaces = {
      "enp5s0" = {
        name = "enp5s0";
        useDHCP = true;
        wakeOnLan = {
          enable = true;
          policy = [ "magic" ];
        };
        ipv4.addresses = [
          {
            address = "188.34.136.238";
            prefixLength = 26;
          }
        ];
        ipv6.addresses = [
          {
            address = "2a01:4f8:2191:246a::1";
            prefixLength = 64;
          }
        ];
      };
    };
    defaultGateway = {
      address = "188.34.136.193";
      interface = "enp5s0";
    };
    defaultGateway6 = {
      address = "fe80::1";
      interface = "enp5s0";
    };
    nameservers = [
      "127.0.0.1"
      "::1"
    ];
    nat = {
      enable = true;
      enableIPv6 = true;
      externalInterface = "enp5s0";
      internalInterfaces = [
        "ve-+"
        "virbr0"
        "wireguard0"
      ];
    };
    hosts = {
      "172.16.31.1" = [
        "www.tenjin.com"

        "metrics.tenjin.com"

        "media.tenjin.com"
        "track.tenjin.com"
        "public.tenjin.com"
        "private.tenjin.com"

        "ankisync.tenjin.com"
        "uptime.tenjin.com"
        "cvat.tenjin.com"
      ];
      "fd17:216b:31bc:1::1" = [
        "www.tenjin.com"

        "metrics.tenjin.com"

        "media.tenjin.com"
        "track.tenjin.com"
        "public.tenjin.com"
        "private.tenjin.com"

        "ankisync.tenjin.com"
        "uptime.tenjin.com"
        "cvat.tenjin.com"
      ];
    };
    firewall = {
      enable = true;
      allowedUDPPorts = [
        # Proxy
        # 1080
        # 3128
        # Wireguard
        51280
      ];
      allowedTCPPorts = [
        # HTTP
        80
        # HTTPS
        443
        # Proxy
        1080
        3128
        # ssh
        57255
      ];
      interfaces."podman+" = {
        allowedTCPPorts = [ 53 ];
        allowedUDPPorts = [ 53 ];
      };
      #todo: actually tide it up
      interfaces."wireguard0" = {
        allowedUDPPorts = [
          # forward all possible dns ports
          53
          67
          5353
          8053
        ];
        allowedTCPPorts = [
          53
          67
          5353
          8053
          # 3001
          # # prometheus
          # 9000

          # #radarr
          # 7878
          # # sonarr
          # 8989
          # # lidarr
          # 8686
          # # readarr
          # 8787
          # # prowlarr
          # 9696
          # # bazarr
          # 8763
          # # jackett
          # 9117
          # # transmission
          # 9091
          # 18765
        ];
      };
    };
  };
  # # Ensures sshd starts after WireGuard0
  systemd.services.sshd = {
    after = [ "wg-quick-wireguard0.service" ];
    wants = [ "wg-quick-wireguard0.service" ];
  };
  services = {
    openssh = {
      enable = true;
      allowSFTP = true;
      openFirewall = true;
      settings = {
        UseDns = true;
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = true;
        PermitRootLogin = "prohibit-password";
      };
      listenAddresses = [
        {
          addr = "0.0.0.0";
          port = 57255;
        }
        {
          addr = "[::]";
          port = 57255;
        }
        # wireguard0
        {
          addr = "172.16.31.1";
          port = 22;
        }
        {
          addr = "[fd17:216b:31bc:1::1]";
          port = 22;
        }
      ];
    };
    dnscrypt-proxy2 = {
      enable = true;
      settings = {
        listen_addresses = [
          "127.0.0.1:5353"
          "[::1]:5353"
        ];
        ipv6_servers = true;
        doh_servers = false;
        odoh_servers = true;
        require_dnssec = true;
      };
      upstreamDefaults = true;
    };
    unbound = {
      enable = true;
      enableRootTrustAnchor = true;
      resolveLocalQueries = true;
      settings = {
        server = {
          verbosity = 2;
          interface = [
            "127.0.0.1"
            "::1"
            "172.16.31.1"
            "fd17:216b:31bc:1::1"
          ];
          do-ip4 = "yes";
          do-ip6 = "yes";
          do-udp = "yes";
          do-tcp = "yes";
          harden-glue = "yes";
          harden-dnssec-stripped = "yes";
          edns-buffer-size = 1232;
          prefetch = "yes";
          prefetch-key = "yes";
          num-threads = "2";
          hide-identity = "yes";
          hide-version = "yes";
          minimal-responses = "no";
          rrset-roundrobin = "yes";
          access-control = [
            "127.0.0.0/8 allow"
            "172.16.0.0/12 allow"
            "fd00::/8 allow"
            "fd17::/16 allow"
            "fe80::/10 allow"
          ];
          private-domain = [
            "remote.tenjin-dk.com."
            "remote.fumoposting.com."
          ];
          private-address = [
            "10.0.0.0/8"
            "172.16.0.0/12"
            "fd00::/8"
            "fd17::/16"
            "fe80::/10"
          ];
          local-zone = [
            "\"internal.com.\" static"
            "\"172.in-addr.arpa.\" static"
            "\"tenjin.com.\" static"
          ];
          identity = "\"static.unsigned-int64.your-server.de\"";
          local-data = [
            "\"internal.com. 10800 IN NS ns1.internal.com.\""
            "\"internal.com. 10800 IN SOA ns1.internal.com. admin@cloud.tenjin-dk.com. 1 3600 1200 604800 10800\""
            "\"internal.com. 10800 IN A 172.16.31.1\""
            "\"internal.com. 10800 IN AAAA fd17:216b:31bc:1::1\""
            "\"ns1.internal.com. 10800 IN A 172.16.31.1\""
            "\"ns1.internal.com. 10800 IN AAAA fd17:216b:31bc:1::1\""

            "\"172.in-addr.arpa. 10800 IN NS internal.com.\""
            "\"172.in-addr.arpa. 10800 IN SOA internal.com. admin@cloud.tenjin-dk.com. 2 3600 1200 604800 10800\""
            "\"1.31.16.172.in-addr.arpa. 10800 IN PTR internal.com.\""

            "\"tenjin.com. 10800 IN NS ns1.internal.com.\""
            "\"tenjin.com. 10800 IN SOA ns1.internal.com. admin@cloud.tenjin-dk.com. 1 3600 1200 604800 10800\""
            "\"tenjin.com. 10800 IN A 172.16.31.1\""
            "\"tenjin.com. 10800 IN AAAA fd17:216b:31bc:1::1\""
            "\"www.tenjin.com. 10800 IN CNAME tenjin.com.\""
            # CNAME
            # metrics
            "\"metrics.tenjin.com. 10800 IN CNAME www.tenjin.com.\""

            # Torrent and Media
            "\"media.tenjin.com. 10800 IN CNAME www.tenjin.com.\"" # Jellyfin instance
            "\"track.tenjin.com. 10800 IN CNAME www.tenjin.com.\"" # track torrents
            "\"public.tenjin.com. 10800 IN CNAME www.tenjin.com.\"" # public transmission instance
            "\"private.tenjin.com. 10800 IN CNAME www.tenjin.com.\"" # private transmission instance

            # Utils
            "\"ankisync.tenjin.com. 10800 IN CNAME www.tenjin.com.\"" # ankisyncing service
            "\"uptime.tenjin.com. 10800 IN CNAME www.tenjin.com.\"" # uptime check (should be outsourced)
            "\"cvat.tenjin.com. 10800 IN CNAME www.tenjin.com.\"" # CVAT instance
          ];
        };
        forward-zone = [
          {
            name = ".";
            forward-addr = [
              # dnscrypt odoh
              "127.0.0.1@5353"
              "::1"

              # Authoritive recursive DNS for robot.hetzner
              "185.12.64.1"
              "185.12.64.2"
              "2a01:4ff:ff00::add:1"
              "2a01:4ff:ff00::add:2"

              # Backup cloudflare DoT
              "1.1.1.1@853#cloudflare-dns.com"
              "1.0.0.1@853#cloudflare-dns.com"
              "2606:4700:4700::1111@853#cloudflare-dns.com"
              "2606:4700:4700::1001@853#cloudflare-dns.com"
            ];
            forward-tls-upstream = "yes";
          }
        ];
        remote-control = {
          control-enable = true;
          control-interface = [
            "127.0.0.1"
            "::1"
            "172.16.31.1"
            "fd17:216b:31bc:1::1"
          ];
          control-port = 8953;
        };
      };
    };
    vnstat.enable = true;
  };
}
