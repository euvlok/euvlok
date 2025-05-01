{ config, ... }:
{
  sops.secrets.tailscale_auth = { };
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
    openFirewall = true;
    authKeyFile = config.sops.secrets.tailscale_auth.path;
    extraUpFlags = [
      "--ssh"
      "--advertise-exit-node"
    ];
  };
}
