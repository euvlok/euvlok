{
  pkgs,
  lib,
  config,
  ...
}:
{
  networking = {
    hostName = "signed-int16";
    hostId = "ac9d16f9";
    nat = {
      enable = true;
      enableIPv6 = false;
      externalInterface = "enp4s0";
      internalInterfaces = [ "ve-+" ];
    };
    networkmanager = {
      enable = true;
      unmanaged = [ "interface-name:ve-*" ];
    };
    firewall.enable = true;
  };
  services.resolved.enable = true;
  services.openssh = {
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
        addr = "192.168.1.1";
        port = 22;
      }
    ];
  };

  sops.secrets.wireguard-client_fumono = { };
  sops.secrets.wireguard-shared_fumono = { };

  services.wg-netmanager.enable = true;
  networking.wireguard.enable = true;
  networking.wg-quick.interfaces = {
    wg-ui64 = {
      address = [
        "172.16.31.10/32"
        "fd17:216b:31bc:1::10/128"
      ];
      dns = [ "172.16.31.1" ];
      privateKeyFile = config.sops.secrets.wireguard-client_fumono.path;
      postUp = ''
        ${lib.getExe' pkgs.systemd "resolvectl"} dns wg-ui64 172.16.31.1
        ${lib.getExe' pkgs.systemd "resolvectl"} domain wg-ui64 ~tenjin.com ~internal.com ~\rcon.fumoposting.com
      '';
      peers = [
        {
          publicKey = "X6OBa2aMpoLGx9lYSa+p1U8OAx0iUxAE6Te9Mucu/HQ=";
          presharedKeyFile = config.sops.secrets.wireguard-shared_fumono.path;
          allowedIPs = [
            "172.16.31.1/24"
            "fd17:216b:31bc:1::1/128"
          ];
          endpoint = "www.tenjin-dk.com:51280";
        }
      ];
    };
  };
  services.mullvad-vpn.enable = true;
}
