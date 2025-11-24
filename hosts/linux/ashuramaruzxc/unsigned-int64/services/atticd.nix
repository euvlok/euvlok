{
  inputs,
  pkgs,
  config,
  ...
}:
{
  sops.secrets.atticd-env = {
    mode = "0400";
    owner = "atticd";
    group = "atticd";
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/atticd 0750 atticd atticd -"
    "d /var/lib/atticd/storage 0750 atticd atticd -"
  ];

  services.atticd = {
    enable = true;
    package = inputs.attic.packages.${pkgs.stdenvNoCC.hostPlatform.system}.attic;
    environmentFile = config.sops.secrets.atticd-env.path;
    settings =
      let
        atticHost = "attic.tenjin.com";
      in
      {
        listen = "[::]:${builtins.toString 8081}";
        allowed-hosts = [
          atticHost
        ]
        ++ [
          "attic.tenjin-dk.com"
        ];
        api-endpoint = "https://${atticHost}/";
        database.url = "postgresql:///atticd?host=/run/postgresql";
        storage = {
          type = "local";
          path = "/var/lib/atticd/storage";
        };
        chunking = {
          nar-size-threshold = 64 * 1024;
          min-size = 16 * 1024;
          avg-size = 64 * 1024;
          max-size = 256 * 1024;
        };
        compression = {
          type = "zstd";
        };
      };
  };
}
