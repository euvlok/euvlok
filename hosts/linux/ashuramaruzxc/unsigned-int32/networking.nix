{
  lib,
  pkgs,

  config,
  ...
}:
{
  sops.secrets.tailscale-auth-key = { };
  networking = {
    hostName = "unsigned-int32";
    hostId = "ab5d64f5";
    nat = {
      enable = true;
      enableIPv6 = true;
      externalInterface = "enp59s0";
      internalInterfaces = [ "ve-+" ];
    };
    networkmanager = {
      enable = true;
      unmanaged = [ "interface-name:ve-*" ];
    };
    firewall = {
      enable = true;
      allowPing = true;
      allowedUDPPorts = [
        25565
        15800
      ];
      allowedTCPPorts = [
        80
        443
      ];
    };
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
        addr = "0.0.0.0";
        port = 57255;
      }
      {
        addr = "[::]";
        port = 57255;
      }
      {
        addr = "192.168.1.100";
        port = 22;
      }
      {
        addr = "192.168.1.101";
        port = 22;
      }
      {
        addr = "192.168.1.150";
        port = 22;
      }
      {
        addr = "172.16.31.3";
        port = 22;
      }
    ];
  };
  services.wg-netmanager.enable = true;
  networking.wireguard.enable = true;
  services.mullvad-vpn = {
    enable = true;
    package = pkgs.mullvad-vpn;
    enableExcludeWrapper = false;
  };
  services.v2raya.enable = true;
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
    openFirewall = true;
    authKeyFile = config.sops.secrets.tailscale-auth-key.path;
    extraUpFlags = [ "--ssh" ];
  };
  systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
  systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false;
}
