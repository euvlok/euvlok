{
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
    package = pkgs.nextcloud35;
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
        qownnotesapi
        richdocuments
        previewgenerator
        # misc
        groupfolders
        gpoddersync
        bookmarks
        cookbook
        music
        ;
      # Camera raw previes
      # camerarawpreviews = pkgs.fetchNextcloudApp {
      #   appName = "camerarawpreviews";
      #   homepage = "https://redirect.github.com/ariselseng/camerarawpreviews";
      #   description = "Camera Raw Previews app for Nextcloud";
      #   url = "https://github.com/ariselseng/camerarawpreviews/releases/download/v0.8.7/camerarawpreviews_nextcloud.tar.gz";
      #   sha256 = "sha256-aiMUSJQVbr3xlJkqOaE3cNhdZu3CnPEIWTNVOoG4HSo=";
      #   license = "${lib.licenses.agpl3Only.shortName}";
      #   appVersion = "0.8.7";
      # };
    };
    extraAppsEnable = true;
    hostName = "cloud.tenjin-dk.com";
    https = true;
    caching = {
      redis = true;
      apcu = false;
    };
    maxUploadSize = "500G";
    config.dbtype = "pgsql";
    settings = {
      overwriteprotocol = "https";
      # 64 MiB per request fits Cloudflare Pro and allows 500 GiB within 10,000 DAV chunks.
      "files.chunked_upload.max_size" = 64 * 1024 * 1024;
      forwarded_for_headers = [ "HTTP_CF_CONNECTING_IP" ];
      # Only Cloudflare's published proxies may supply the client address.
      # https://www.cloudflare.com/ips/
      trusted_proxies = [
        "173.245.48.0/20"
        "103.21.244.0/22"
        "103.22.200.0/22"
        "103.31.4.0/22"
        "141.101.64.0/18"
        "108.162.192.0/18"
        "190.93.240.0/20"
        "188.114.96.0/20"
        "197.234.240.0/22"
        "198.41.128.0/17"
        "162.158.0.0/15"
        "104.16.0.0/13"
        "104.24.0.0/14"
        "172.64.0.0/13"
        "131.0.72.0/22"
        "2400:cb00::/32"
        "2606:4700::/32"
        "2803:f800::/32"
        "2405:b500::/32"
        "2405:8100::/32"
        "2a06:98c0::/29"
        "2c0f:f248::/32"
      ];
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
      enableACME = true;
    };
  };
}
