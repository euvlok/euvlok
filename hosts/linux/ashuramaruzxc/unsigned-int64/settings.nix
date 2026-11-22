{ config, lib, ... }:
let
  wanInterface = "enp2s0";
  wireguardIPv4 = "172.16.31.1";
  wireguardIPv6 = "fd17:216b:31bc:1::1";
  publicSshPort = 57255;

  dnsInterfaces = [
    "127.0.0.1"
    "::1"
    wireguardIPv4
    wireguardIPv6
  ];

  tenjinHosts = [
    "www.tenjin.com"
    "metrics.tenjin.com"
    "media.tenjin.com"
    "track.tenjin.com"
    "public.tenjin.com"
    "private.tenjin.com"
    "ankisync.tenjin.com"
    "uptime.tenjin.com"
  ];
in
{
  networking = {
    hostName = "unsigned-int64";
    interfaces.${wanInterface} = {
      useDHCP = true;
      wakeOnLan.enable = true;
      ipv4.addresses = [
        {
          address = "157.90.69.197";
          prefixLength = 25;
        }
      ];
      ipv6.addresses = [
        {
          address = "2a01:4f8:2b02:eb5::1";
          prefixLength = 64;
        }
      ];
    };

    defaultGateway = {
      address = "157.90.69.129";
      interface = wanInterface;
    };
    defaultGateway6 = {
      address = "fe80::1";
      interface = wanInterface;
    };
    networkmanager.ensureProfiles.profiles.ethernet.ipv6.address1 = "2a01:4f8:2b02:eb5::1/64,fe80::1";

    nat = {
      enable = true;
      enableIPv6 = true;
      externalInterface = wanInterface;
      internalInterfaces = [
        "ve-+"
        "virbr0"
        "wireguard0"
      ];
    };

    hosts = {
      ${wireguardIPv4} = tenjinHosts;
      ${wireguardIPv6} = tenjinHosts;
    };

    firewall = {
      allowedUDPPorts = [
        # HTTP/3 (QUIC)
        443
        config.networking.wg-quick.interfaces.wireguard0.listenPort
      ];
      interfaces = {
        "podman+" = {
          allowedTCPPorts = [ 53 ];
          allowedUDPPorts = [ 53 ];
        };
        wireguard0 = {
          allowedTCPPorts = [
            22
            53
            3389
          ];
          allowedUDPPorts = [ 53 ];
        };
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
      ports = [ publicSshPort ];
      settings = {
        UseDns = true;
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = true;
        PermitRootLogin = "prohibit-password";
      };
      listenAddresses = [
        {
          addr = "0.0.0.0";
          port = publicSshPort;
        }
        {
          addr = "[::]";
          port = publicSshPort;
        }
        {
          addr = wireguardIPv4;
          port = 22;
        }
        {
          addr = "[${wireguardIPv6}]";
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
    };

    unbound = {
      enable = true;
      settings = {
        server = {
          interface = dnsInterfaces;
          verbosity = 2;
          prefetch = "yes";
          prefetch-key = "yes";
          num-threads = 2;
          hide-identity = "yes";
          hide-version = "yes";
          minimal-responses = "no";
          access-control = [
            "127.0.0.0/8 allow"
            "172.16.0.0/12 allow"
            "fd00::/8 allow"
            "fe80::/10 allow"
          ];
          private-domain = [ "remote.tenjin-dk.com." ];
          private-address = [
            "10.0.0.0/8"
            "172.16.0.0/12"
            "fd00::/8"
            "fe80::/10"
          ];
          local-zone = [
            ''"internal.com." static''
            ''"172.in-addr.arpa." static''
            ''"tenjin.com." static''
          ];
          local-data = [
            ''"internal.com. 10800 IN NS ns1.internal.com."''
            ''"internal.com. 10800 IN SOA ns1.internal.com. admin@cloud.tenjin-dk.com. 1 3600 1200 604800 10800"''
            ''"172.in-addr.arpa. 10800 IN NS internal.com."''
            ''"172.in-addr.arpa. 10800 IN SOA internal.com. admin@cloud.tenjin-dk.com. 2 3600 1200 604800 10800"''
            ''"1.31.16.172.in-addr.arpa. 10800 IN PTR internal.com."''
            ''"tenjin.com. 10800 IN NS ns1.internal.com."''
            ''"tenjin.com. 10800 IN SOA ns1.internal.com. admin@cloud.tenjin-dk.com. 1 3600 1200 604800 10800"''
          ]
          ++
            lib.lists.concatMap
              (hostname: [
                ''"${hostname}. 10800 IN A ${wireguardIPv4}"''
                ''"${hostname}. 10800 IN AAAA ${wireguardIPv6}"''
              ])
              (
                [
                  "internal.com"
                  "ns1.internal.com"
                  "tenjin.com"
                ]
                ++ tenjinHosts
              );
        };

        forward-zone = [
          {
            name = ".";
            forward-tls-upstream = "yes";
            forward-addr = [
              "185.12.64.1"
              "185.12.64.2"
              "2a01:4ff:ff00::add:1"
              "2a01:4ff:ff00::add:2"
              "1.1.1.1@853#cloudflare-dns.com"
              "1.0.0.1@853#cloudflare-dns.com"
              "2606:4700:4700::1111@853#cloudflare-dns.com"
              "2606:4700:4700::1001@853#cloudflare-dns.com"
            ];
          }
        ];

        remote-control = {
          control-enable = true;
          control-interface = dnsInterfaces;
        };
      };
    };

    vnstat.enable = true;
  };
}
