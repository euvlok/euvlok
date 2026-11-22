{
  pkgs,
  lib,
  config,
  ...
}:
let
  wanInterface = config.networking.nat.externalInterface;
  iptables = lib.meta.getExe' pkgs.iptables "iptables";
in
{
  sops.secrets.wireguard-server = { };
  sops.secrets.wireguard-shared = { };
  networking.wg-quick.interfaces.wireguard0 = {
    address = [
      "172.16.31.1/24"
    ];
    listenPort = 51280;
    privateKeyFile = config.sops.secrets.wireguard-server.path;
    postUp = ''
      ${iptables} -t nat -A PREROUTING -i ${wanInterface} -p tcp --dport 45565 -j DNAT --to-destination 172.16.31.2:25565
      ${iptables} -t nat -A POSTROUTING -o wireguard0 -p tcp --sport 45565 -j SNAT --to-source 172.16.31.1:25565
      ${iptables} -A FORWARD -i ${wanInterface} -o wireguard0 -p tcp --dport 45565 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
      ${iptables} -A FORWARD -i wireguard0 -o ${wanInterface} -p tcp --sport 45565 -m state --state ESTABLISHED,RELATED -j ACCEPT
    '';
    postDown = ''
      ${iptables} -t nat -D PREROUTING -i ${wanInterface} -p tcp --dport 45565 -j DNAT --to-destination 172.16.31.2:25565
      ${iptables} -t nat -D POSTROUTING -o wireguard0 -p tcp --sport 45565 -j SNAT --to-source 172.16.31.1:25565
      ${iptables} -D FORWARD -i ${wanInterface} -o wireguard0 -p tcp --dport 45565 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
      ${iptables} -D FORWARD -i wireguard0 -o ${wanInterface} -p tcp --sport 45565 -m state --state ESTABLISHED,RELATED -j ACCEPT
    '';
    peers = [
      # ashuramaru@rt-be88u
      {
        publicKey = "h3xpCukBxMTgNG1PE3PyxNuWpuqS2IpACW5ZC8Pjjgc=";
        presharedKeyFile = config.sops.secrets.wireguard-shared.path;
        allowedIPs = [
          "172.16.31.2/32"
        ];
      }
    ];
  };
}
