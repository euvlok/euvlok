{ config, ... }:
{
  sops.secrets.shadowsocks = {
    mode = "0775";
    owner = config.users.users.nobody.name;
    group = config.users.users.nobody.group;
  };

  services.shadowsocks = {
    enable = true;
    fastOpen = true;
    port = 1080;
    mode = "tcp_only";
    localAddress = [
      "172.16.31.1"
      "[fd17:216b:31bc:1::1]"
    ];
    passwordFile = config.sops.secrets.shadowsocks.path;
  };
  networking.firewall.interfaces."wireguard0" = {
    allowedTCPPorts = [ 1080 ];
  };
}
