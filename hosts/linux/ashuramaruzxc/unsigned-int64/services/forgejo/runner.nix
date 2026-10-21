{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.forgejo;
  secretFile = "${cfg.customDir}/conf/runner_secret";
  # The first 16 ASCII bytes identify the runner. Only the random suffix is secret.
  runnerId = "756e7369676e6564";
in
{
  systemd.services.forgejo-secrets.script = lib.mkAfter ''
    if [ ! -s '${secretFile}' ]; then
      printf '%s%s' '${runnerId}' "$(${pkgs.openssl}/bin/openssl rand -hex 12)" > '${secretFile}.tmp'
      mv '${secretFile}.tmp' '${secretFile}'
    fi
  '';

  systemd.services.forgejo-runner-register = {
    description = "Register the single local Forgejo runner";
    requires = [ "forgejo.service" ];
    after = [ "forgejo.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = cfg.user;
      Group = cfg.group;
      WorkingDirectory = cfg.stateDir;
      UMask = "0077";
      ExecStart = "${lib.getExe cfg.package} --config ${cfg.customDir}/conf/app.ini forgejo-cli actions register --name unsigned-int64-local --keep-labels --secret-file ${secretFile}";
    };
    environment = {
      FORGEJO_WORK_DIR = cfg.stateDir;
      FORGEJO_CUSTOM = cfg.customDir;
    };
  };

  services.forgejo-runner = {
    package = pkgs.forgejo-runner;
    instances.local = {
      enable = true;
      settings = {
        log.level = "info";
        runner = {
          capacity = 1;
          labels = [ "native:host" ];
          timeout = "3h";
          shutdown_timeout = "30s";
          insecure = false;
          fetch_timeout = "30s";
          fetch_interval = "2s";
        };
        cache.enabled = false;
        server.connections.local = {
          url = cfg.settings.server.LOCAL_ROOT_URL;
          # UUID formed from runnerId's ASCII bytes by Forgejo's offline registration.
          uuid = "37353665-3733-3639-3637-366536353634";
          token = null;
        };
      };
      secrets.server.connections.local.token_url = secretFile;
      runtimes = {
        host = true;
        docker = false;
        podman = false;
      };
      hostPackages = lib.attrValues {
        inherit (pkgs)
          bash
          coreutils
          curl
          gawk
          git
          git-lfs
          gnused
          gnutar
          gzip
          jq
          nix
          nodejs
          openssh
          unzip
          ;
      };
    };
  };

  systemd.services.forgejo-runner-local = {
    requires = [ "forgejo-runner-register.service" ];
    after = [ "forgejo-runner-register.service" ];
    serviceConfig = {
      UMask = "0077";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
    };
  };
}
