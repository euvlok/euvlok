{ config, ... }:
{
  sops.secrets.tailscale_auth.restartUnits = [ "tailscaled-autoconnect.service" ];
  services.tailscale = {
    enable = true;
    openFirewall = true;
    authKeyFile = config.sops.secrets.tailscale_auth.path;
    # Tag requests are supported by `tailscale up`, not `tailscale set`.
    extraUpFlags = [
      "--advertise-tags=tag:unsigned-int64"
      "--advertise-exit-node"
      "--ssh=true"
    ];
    extraSetFlags = [ "--ssh=true" ];
  };
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
    # Keep the static IPv6 address when NetworkManager reapplies Ethernet.
    networkmanager.ensureProfiles.profiles.ethernet.ipv6.address1 = "2a01:4f8:2191:246a::1/64,fe80::1";
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
      ];
      # The tailnet policy permits SSH only from tag:unsigned-int8.
      interfaces.${config.services.tailscale.interfaceName}.allowedTCPPorts = [ 57255 ];
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
          22
          53
          67
          5353
          8053
          3389
        ];
      };
    };
  };
  systemd.services.sshd = {
    after = [ "wg-quick-wireguard0.service" ];
    wants = [ "wg-quick-wireguard0.service" ];
  };
  services = {
    openssh = {
      enable = true;
      allowSFTP = true;
      openFirewall = true;
      ports = [ 57255 ];
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
    dnscrypt-proxy = {
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
          private-domain = [ "remote.tenjin-dk.com." ];
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
            "\"www.tenjin.com. 10800 IN A 172.16.31.1\""
            "\"www.tenjin.com. 10800 IN AAAA fd17:216b:31bc:1::1\""
            # Static local zones need direct address records for these aliases.
            # metrics
            "\"metrics.tenjin.com. 10800 IN A 172.16.31.1\""
            "\"metrics.tenjin.com. 10800 IN AAAA fd17:216b:31bc:1::1\""

            # Torrent and Media
            "\"media.tenjin.com. 10800 IN A 172.16.31.1\"" # Jellyfin instance
            "\"media.tenjin.com. 10800 IN AAAA fd17:216b:31bc:1::1\""
            "\"track.tenjin.com. 10800 IN A 172.16.31.1\"" # track torrents
            "\"track.tenjin.com. 10800 IN AAAA fd17:216b:31bc:1::1\""
            "\"public.tenjin.com. 10800 IN A 172.16.31.1\"" # public transmission instance
            "\"public.tenjin.com. 10800 IN AAAA fd17:216b:31bc:1::1\""
            "\"private.tenjin.com. 10800 IN A 172.16.31.1\"" # private transmission instance
            "\"private.tenjin.com. 10800 IN AAAA fd17:216b:31bc:1::1\""

            # Utils
            "\"ankisync.tenjin.com. 10800 IN A 172.16.31.1\"" # ankisyncing service
            "\"ankisync.tenjin.com. 10800 IN AAAA fd17:216b:31bc:1::1\""
            "\"uptime.tenjin.com. 10800 IN A 172.16.31.1\"" # uptime check (should be outsourced)
            "\"uptime.tenjin.com. 10800 IN AAAA fd17:216b:31bc:1::1\""
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
