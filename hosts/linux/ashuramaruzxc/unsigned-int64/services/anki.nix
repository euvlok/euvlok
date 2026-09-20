{ config, ... }:
{
  sops.secrets.anki_kunny = { };
  sops.secrets.anki_tenjin = { };

  services.anki-sync-server = {
    enable = true;
    openFirewall = true;
    address = "127.0.0.1";
    users = [
      {
        username = "kunny";
        passwordFile = config.sops.secrets.anki_kunny.path;
      }
      {
        username = "tenjin";
        passwordFile = config.sops.secrets.anki_tenjin.path;
      }
    ];
  };

  services.nginx.virtualHosts."ankisync.tenjin-dk.com" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:27701";
      proxyWebsockets = true;
    };
  };
}
