{ lib, ... }:
{
  services.immich = {
    enable = true;
    host = "127.0.0.1";
    port = 2283;
    # Nginx is the only public entry point.
    openFirewall = false;

    mediaLocation = "/mnt/media/immich";
    accelerationDevices = [ "/dev/dri/renderD128" ];

    database = {
      enable = true;
      createDB = true;
    };
    redis.enable = true;

    environment = {
      # The 7950X3D has 16 physical cores. Leaving SMT capacity outside this
      # budget keeps the API and the other services on this host responsive.
      CPU_CORES = "16";
      IMMICH_TRUSTED_PROXIES = "127.0.0.1,::1";
      LIBVA_DRIVER_NAME = "radeonsi";
      TZ = "Europe/Berlin";
    };

    machine-learning.environment = {
      # One worker avoids loading a second copy of every model into memory.
      MACHINE_LEARNING_WORKERS = "1";
      MACHINE_LEARNING_REQUEST_THREADS = "8";
      MACHINE_LEARNING_MODEL_INTER_OP_THREADS = "1";
      MACHINE_LEARNING_MODEL_INTRA_OP_THREADS = "4";
      MACHINE_LEARNING_MODEL_TTL = "1800";
      MACHINE_LEARNING_WORKER_TIMEOUT = lib.mkForce "300";
    };

    settings = {
      newVersionCheck.enabled = false;
      server.externalDomain = "https://photos.tenjin-dk.com";

      ffmpeg = {
        accel = "vaapi";
        accelDecode = true;
        preferredHwDevice = "/dev/dri/renderD128";
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
        lazyfree-lazy-eviction = true;
        lazyfree-lazy-expire = true;
        lazyfree-lazy-server-del = true;
      };
    };
  };

  users.users.immich.extraGroups = [
    "render"
    "video"
  ];

  systemd.tmpfiles.rules = [
    "d /mnt/media/immich 0700 immich immich -"
  ];
  systemd.services.immich-server.unitConfig.RequiresMountsFor = "/mnt/media/immich";

  services.nginx.virtualHosts."photos.tenjin-dk.com" = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:2283";
      proxyWebsockets = true;
      recommendedProxySettings = true;

      extraConfig = ''
        client_max_body_size 50000M;
        client_body_buffer_size 1024k;
        proxy_request_buffering off;
        proxy_read_timeout 600s;
        proxy_send_timeout 600s;
        send_timeout 600s;
      '';
    };
  };
}
