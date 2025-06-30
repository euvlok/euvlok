{ lib, ... }:
{
  networking = {
    hostName = "unsigned-int16";
    hostId = "8425e349";
    nat = {
      enable = true;
      enableIPv6 = true;
      externalInterface = "end0";
      internalInterfaces = [
        "ve-+"
        "virbr0"
      ];
    };
    interfaces = {
      "end0" = {
        name = "end0";
        useDHCP = true;
        wakeOnLan = {
          enable = true;
          policy = [ "magic" ];
        };
      };
    };
    firewall = {
      enable = true;
      allowPing = true;
      allowedTCPPorts = [
        # HTTP
        80
        # Dns
        53
        5353
        # HTTPS
        443
        # Proxy
        1080
        3128
      ];
      allowedUDPPorts = [
        53
        5353
      ];
    };
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
          port = 22;
        }
        {
          addr = "[::]";
          port = 22;
        }
      ];
    };
    services.wg-netmanager.enable = true;
    networking.wireguard.enable = true;
    services.mullvad-vpn = {
      enable = true;
      enableExcludeWrapper = false;
    };
    services.v2raya.enable = true;
    # services.tailscale = {
    #   enable = true;
    #   useRoutingFeatures = "both";
    #   openFirewall = true;
    #   authKeyFile = config.sops.secrets.tailscale_auth.path;
    # };
    vnstat.enable = true;
    systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
    systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false;
  };
}
