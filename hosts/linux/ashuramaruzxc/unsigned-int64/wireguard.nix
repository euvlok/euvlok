{
  pkgs,
  lib,
  config,
  ...
}:
{
  sops.secrets.wireguard-server = { };
  sops.secrets.wireguard-shared = { };
  sops.secrets.wireguard-shared_fumono = { };
  networking.wg-quick.interfaces.wireguard0 = {
    address = [
      "172.16.31.1/24"
      "fd17:216b:31bc:1::1/64"
    ];
    listenPort = 51280;
    privateKeyFile = config.sops.secrets.wireguard-server.path;
    postUp = ''
      ${lib.getExe' pkgs.iptables "iptables"} -t nat -A PREROUTING -i eth0 -p tcp --dport 45565 -j DNAT --to-destination 172.16.31.2:25565
      ${lib.getExe' pkgs.iptables "iptables"} -t nat -A POSTROUTING -o wireguard0 -p tcp --sport 45565 -j SNAT --to-source 172.16.31.1:25565
      ${lib.getExe' pkgs.iptables "iptables"} -A FORWARD -i eth0 -o wireguard0 -p tcp --dport 45565 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
      ${lib.getExe' pkgs.iptables "iptables"} -A FORWARD -i wireguard0 -o eth0 -p tcp --sport 45565 -m state --state ESTABLISHED,RELATED -j ACCEPT
    '';
    postDown = ''
      ${lib.getExe' pkgs.iptables "iptables"} -t nat -D PREROUTING -i eth0 -p tcp --dport 45565 -j DNAT --to-destination 172.16.31.2:25565
      ${lib.getExe' pkgs.iptables "iptables"} -t nat -D POSTROUTING -o wireguard0 -p tcp --sport 45565 -j SNAT --to-source 172.16.31.1:25565
      ${lib.getExe' pkgs.iptables "iptables"} -D FORWARD -i eth0 -o wireguard0 -p tcp --dport 45565 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
      ${lib.getExe' pkgs.iptables "iptables"} -D FORWARD -i wireguard0 -o eth0 -p tcp --sport 45565 -m state --state ESTABLISHED,RELATED -j ACCEPT
    '';
    peers = [
      # Clares@rt-ax86u
      {
        publicKey = "Qn6WDn9CHgla44vuo31whTen+Hj581dnHwJKQfWVOXY=";
        presharedKeyFile = config.sops.secrets.wireguard-shared.path;
        allowedIPs = [
          "172.16.31.2/32"
          "fd17:216b:31bc:1::2/128"
        ];
      }
      {
        publicKey = "w5lvJLqFUliUA9jBdKl7B5KB35L87hBK3n786yUgvSk=";
        presharedKeyFile = config.sops.secrets.wireguard-shared.path;
        allowedIPs = [
          "172.16.31.5/32"
          "fd17:216b:31bc:1::5/128"
        ];
      }
      {
        # root@v1
        publicKey = "4WCatIaSouTOmlpVjHWsB3zZN6ikStYGyg6esqejhQo=";
        presharedKeyFile = config.sops.secrets.wireguard-shared_fumono.path;
        allowedIPs = [
          "172.16.31.10/32"
          "fd17:216b:31bc:1::10/128"
        ];
      }
    ];
  };
}
