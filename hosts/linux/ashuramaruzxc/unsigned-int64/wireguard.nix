{
  pkgs,
  lib,
  config,
  ...
}:
let
  externalInterface = config.networking.nat.externalInterface;
  externalAddress =
    (builtins.head config.networking.interfaces.${externalInterface}.ipv4.addresses).address;
  iptables = lib.meta.getExe' pkgs.iptables "iptables";
in
{
  sops.secrets.wireguard-server = { };
  sops.secrets.wireguard-shared = { };
  networking.wg-quick.interfaces.wireguard0 = {
    address = [
      "172.16.31.1/24"
      "fd17:216b:31bc:1::1/64"
    ];
    listenPort = 51280;
    privateKeyFile = config.sops.secrets.wireguard-server.path;
    # Match the public tuple before DNAT and the backend tuple after DNAT
    # SNAT only this forward so the backend replies through the server
    postUp = ''
      ${iptables} -t nat -A PREROUTING \
        -i ${externalInterface} -d ${externalAddress} -p tcp --dport 45565 \
        -j DNAT --to-destination 172.16.31.2:25565
      ${iptables} -t nat -A POSTROUTING \
        -o wireguard0 -d 172.16.31.2 -p tcp --dport 25565 \
        -m conntrack --ctstate DNAT --ctdir ORIGINAL \
        --ctorigdst ${externalAddress} --ctorigdstport 45565 \
        -j SNAT --to-source 172.16.31.1
      ${iptables} -A FORWARD \
        -i ${externalInterface} -o wireguard0 \
        -d 172.16.31.2 -p tcp --dport 25565 \
        -m conntrack --ctstate NEW,ESTABLISHED --ctdir ORIGINAL \
        --ctorigdst ${externalAddress} --ctorigdstport 45565 -j ACCEPT
      ${iptables} -A FORWARD \
        -i wireguard0 -o ${externalInterface} \
        -s 172.16.31.2 -p tcp --sport 25565 \
        -m conntrack --ctstate ESTABLISHED --ctdir REPLY \
        --ctorigdst ${externalAddress} --ctorigdstport 45565 -j ACCEPT
    '';
    postDown = ''
      ${iptables} -t nat -D PREROUTING \
        -i ${externalInterface} -d ${externalAddress} -p tcp --dport 45565 \
        -j DNAT --to-destination 172.16.31.2:25565
      ${iptables} -t nat -D POSTROUTING \
        -o wireguard0 -d 172.16.31.2 -p tcp --dport 25565 \
        -m conntrack --ctstate DNAT --ctdir ORIGINAL \
        --ctorigdst ${externalAddress} --ctorigdstport 45565 \
        -j SNAT --to-source 172.16.31.1
      ${iptables} -D FORWARD \
        -i ${externalInterface} -o wireguard0 \
        -d 172.16.31.2 -p tcp --dport 25565 \
        -m conntrack --ctstate NEW,ESTABLISHED --ctdir ORIGINAL \
        --ctorigdst ${externalAddress} --ctorigdstport 45565 -j ACCEPT
      ${iptables} -D FORWARD \
        -i wireguard0 -o ${externalInterface} \
        -s 172.16.31.2 -p tcp --sport 25565 \
        -m conntrack --ctstate ESTABLISHED --ctdir REPLY \
        --ctorigdst ${externalAddress} --ctorigdstport 45565 -j ACCEPT
    '';
    peers = [
      # ashuramaru@rt-be88u
      {
        publicKey = "h3xpCukBxMTgNG1PE3PyxNuWpuqS2IpACW5ZC8Pjjgc=";
        presharedKeyFile = config.sops.secrets.wireguard-shared.path;
        allowedIPs = [
          "172.16.31.2/32"
          "fd17:216b:31bc:1::2/128"
        ];
      }
    ];
  };
}
