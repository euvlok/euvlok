{
  config,
  lib,
  ...
}:
let
  cfg = config.services.immich;
  domain = "photos.tenjin-dk.com";
  mediaLocation = "/mnt/media/immich";
  renderDevice = "/dev/dri/renderD128";
in
{
  services.immich = {
    enable = true;
    host = "127.0.0.1";
    port = 2283;
    # Nginx is the only public entry point.
    openFirewall = false;

    inherit mediaLocation;
    accelerationDevices = [ renderDevice ];

    database = {
      enable = true;
      createDB = true;
    };
    redis.enable = true;

    environment = {
      # The 7950X3D has 16 physical cores. Leaving SMT capacity outside this
      # budget keeps the API and the other services on this host responsive.
      CPU_CORES = "16";
      IMMICH_TRUSTED_PROXIES = "${cfg.host},::1";
      LIBVA_DRIVER_NAME = "radeonsi";
      TZ = config.time.timeZone;
    };

    machine-learning.environment = {
      # A second worker would load another copy of every model into memory.
      MACHINE_LEARNING_WORKERS = "1";
      MACHINE_LEARNING_REQUEST_THREADS = "8";
      MACHINE_LEARNING_MODEL_INTER_OP_THREADS = "1";
      MACHINE_LEARNING_MODEL_INTRA_OP_THREADS = "4";
      MACHINE_LEARNING_MODEL_TTL = "1800";
      # The pinned NixOS module still sets 120 seconds at normal priority.
      MACHINE_LEARNING_WORKER_TIMEOUT = lib.mkForce "300";
    };

    settings = {
      newVersionCheck.enabled = false;
      server.externalDomain = "https://${domain}";

      ffmpeg = {
        accel = "vaapi";
        accelDecode = true;
        preferredHwDevice = renderDevice;
        preset = "slow";
        targetResolution = "1080";
        targetVideoCodec = "h264";
        transcode = "required";
      };

      # Higher-throughput queues sized for 16 Zen 4 cores. CPU-heavy queues
      # stay below the core count, and VA-API conversion remains conservative.
      job = {
        backgroundTask.concurrency = 8;
        faceDetection.concurrency = 4;
        library.concurrency = 8;
        metadataExtraction.concurrency = 12;
        migration.concurrency = 8;
        notifications.concurrency = 8;
        ocr.concurrency = 2;
        search.concurrency = 8;
        sidecar.concurrency = 8;
        smartSearch.concurrency = 4;
        thumbnailGeneration.concurrency = 12;
        videoConversion.concurrency = 2;
      };
    };
  };

  # Immich uses Redis for its BullMQ job queues. Keep it private on a Unix
  # socket, preserve queued work across restarts, and never evict queue keys.
  services.redis = {
    vmOverCommit = true;
    servers.immich = {
      port = 0;
      openFirewall = false;
      unixSocket = "/run/redis-immich/redis.sock";
      unixSocketPerm = 660;

      databases = 1;
      maxclients = 1024;
      appendOnly = true;
      appendFsync = "everysec";
      save = [
        [
          3600
          1
        ]
        [
          300
          100
        ]
      ];

      settings = {
        maxmemory-policy = "noeviction";
        aof-use-rdb-preamble = true;
        lazyfree-lazy-expire = true;
        lazyfree-lazy-server-del = true;
      };
    };
  };

  users.users.${cfg.user}.extraGroups = [
    "render"
    "video"
  ];

  systemd = {
    tmpfiles.settings.immich.${mediaLocation}.d = {
      mode = "0700";
      inherit (cfg) user group;
    };
    services.immich-server.unitConfig.RequiresMountsFor = mediaLocation;
  };

  services.nginx.virtualHosts.${domain} = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://${cfg.host}:${toString cfg.port}";
      proxyWebsockets = true;
      recommendedProxySettings = true;

      extraConfig = ''
        client_max_body_size 50000M;
        client_body_buffer_size 1024k;
        proxy_request_buffering off;

        proxy_read_timeout 600s;
        proxy_send_timeout 600s;
        send_timeout 600s;

        proxy_cookie_path off;
      '';
    };
  };
}
