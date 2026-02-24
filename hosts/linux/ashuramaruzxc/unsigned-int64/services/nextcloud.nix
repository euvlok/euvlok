{
  lib,
  config,
  pkgs,
  ...
}:
{
  sops.secrets.admin = {
    mode = "0740";
    owner = "nextcloud";
    group = "nextcloud";
  };
  services.nextcloud = {
    enable = true;
    enableImagemagick = true;
    database.createLocally = true;
    package = pkgs.nextcloud32;
    settings = {
      enablePreview = true;
      enabledPreviewProviders = [
        "OC\\Preview\\XBitmap"
        "OC\\Preview\\Image"
        "OC\\Preview\\PNG"
        "OC\\Preview\\MJPEG"
        "OC\\Preview\\JPEG"
        "OC\\Preview\\WEBP"
        "OC\\Preview\\BMP"
        "OC\\Preview\\HEIC"
        "OC\\Preview\\SVG"
        "OC\\Preview\\TIFF"
        "OC\\Preview\\EMF"
        "OC\\Preview\\Font"
        "OC\\Preview\\Illustrator"
        "OC\\Preview\\Photoshop"
        "OC\\Preview\\Krita"
        "OC\\Preview\\FLAC"
        "OC\\Preview\\WAV"
        "OC\\Preview\\OGG"
        "OC\\Preview\\AAC"
        "OC\\Preview\\M4A"
        "OC\\Preview\\MP3"
        "OC\\Preview\\Movie"
        "OC\\Preview\\MP4"
        "OC\\Preview\\MKV"
        "OC\\Preview\\AVI"
        "OC\\Preview\\GIF"
        "OC\\Preview\\TXT"
        "OC\\Preview\\OpenDocument"
        "OC\\Preview\\Postscript"
        "OC\\Preview\\MSOffice2003"
        "OC\\Preview\\MSOffice2007"
        "OC\\Preview\\MSOfficeDoc"
        "OC\\Preview\\StarOffice"
        "OC\\Preview\\MarkDown"
        "OC\\Preview\\PDF"
      ];
    };

    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps)
        # admin
        user_oidc
        notify_push
        twofactor_webauthn
        # twofactor_nextcloud_notification
        # ical
        calendar
        contacts
        deck
        # productivity
        mail
        polls
        forms
        tasks
        spreed
        onlyoffice
        qownnotesapi
        richdocuments
        previewgenerator
        # misc
        groupfolders
        gpoddersync
        bookmarks
        cookbook
        cospend
        music
        # maps
        ;
      # Camera raw previes
      camerarawpreviews = pkgs.fetchNextcloudApp {
        appName = "camerarawpreviews";
        homepage = "https:2//github.com/ariselseng/camerarawpreviews";
        description = "Camera Raw Previews app for Nextcloud";
        url = "https://github.com/ariselseng/camerarawpreviews/releases/download/v0.8.7/camerarawpreviews_nextcloud.tar.gz";
        sha256 = "sha256-aiMUSJQVbr3xlJkqOaE3cNhdZu3CnPEIWTNVOoG4HSo=";
        license = "${lib.licenses.agpl3Only.shortName}";
        appVersion = "0.8.7";
      };
      integration_paperless = pkgs.fetchNextcloudApp {
        appName = "integration_paperless";
        homepage = "https://apps.nextcloud.com/apps/integration_paperless";
        description = "Integration with the Paperless Document Management System";
        url = "https://github.com/nextcloud-releases/integration_paperless/releases/download/v1.0.6/integration_paperless-v1.0.6.tar.gz";
        sha256 = "sha256-Tw0VZk+ByXLmFdNBgJdFnHUiFarDP+YyulzvCmE3ivw=";
        license = "${lib.licenses.agpl3Only.shortName}";
        appVersion = "1.0.6";
      };
    };
    extraAppsEnable = true;
    hostName = "cloud.tenjin-dk.com";
    https = true;
    caching = {
      redis = true;
      apcu = false;
    };
    maxUploadSize = "500G";
    config = {
      dbtype = "pgsql";
      adminuser = "root";
      adminpassFile = config.sops.secrets.admin.path;
    };
    settings = {
      overwriteprotocol = "https";
      default_phone_region = "UA";
      maintenance_window_start = "1";
      metadata_max_filesize = "256";
      redis = {
        host = "/run/redis-nextcloud/redis.sock";
        port = 0;
      };
      mail_smtpmode = "sendmail";
      mail_sendmailmode = "pipe";
      "memcache.local" = "\\OC\\Memcache\\Redis";
      "memcache.distributed" = "\\OC\\Memcache\\Redis";
      "memcache.locking" = "\\OC\\Memcache\\Redis";
    };
    phpOptions = {
      "opcache.memory_consumption" = "8096M";
      "opcache.interned_strings_buffer" = "16";
      "file_uploads" = "on";
      "upload_max_filesize" = "500G";
      "max_file_uploads" = "10000000";
    };
    phpExtraExtensions = all: [
      all.pdlib
      all.gd
      all.bz2
      all.smbclient
    ];
  };
  services.redis.servers.nextcloud = {
    enable = true;
    port = 0;
    user = "nextcloud";
  };
  services.nginx.virtualHosts = {
    "${config.services.nextcloud.hostName}" = {
      forceSSL = true;
      enableACME = true;
    };
  };
}
