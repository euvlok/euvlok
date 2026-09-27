{ config, lib, ... }:
{
  sops.secrets.tailscale_auth = { };
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
      # The tailnet policy permits SSH only from unsigned-int8.
      interfaces.${config.services.tailscale.interfaceName}.allowedTCPPorts = [ 22 ];
      extraCommands = ''
        ip46tables -I nixos-fw 1 ! -i ${config.services.tailscale.interfaceName} -p tcp --dport 22 -j nixos-fw-refuse
        ip46tables -I nixos-fw 1 -i lo -p tcp --dport 22 -j nixos-fw-accept
      '';
    };
  };
  services.resolved.enable = true;
  services.openssh = {
    enable = true;
    allowSFTP = true;
    openFirewall = false;
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
  services.v2raya.enable = true;
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
    openFirewall = true;
    authKeyFile = config.sops.secrets.tailscale_auth.path;
    # Apply the identity on first login and on already enrolled machines.
    extraUpFlags = config.services.tailscale.extraSetFlags;
    extraSetFlags = [
      "--advertise-tags=tag:unsigned-int32"
      "--ssh=false"
    ];
  };
  systemd.services.NetworkManager-wait-online.enable = lib.modules.mkForce false;
  systemd.services.systemd-networkd-wait-online.enable = lib.modules.mkForce false;
}
