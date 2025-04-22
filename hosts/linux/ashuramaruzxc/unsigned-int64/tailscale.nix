{ config, ... }:
{
  sops.secrets.tailscale-auth-key = { };
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
    openFirewall = true;
    authKeyFile = config.sops.secrets.tailscale-auth-key.path;
    extraUpFlags = [
      "--ssh"
      "--advertise-exit-node"
    ];
  };
}
