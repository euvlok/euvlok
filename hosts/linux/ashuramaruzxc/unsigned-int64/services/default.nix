_: {
  imports = [
    # Most important
    ./nginx.nix
    ./tenjin-tls.nix
    ./grafana.nix
    ./ecoflow.nix

    # utils
    ./fail2ban.nix
    ./msmtp.nix # email

    # media
    ./torrent.nix
    ./jellyfin.nix
    ./immich.nix
    ./anki.nix

    # db
    ./postgresql.nix
    ./redis.nix

    # Misc
    ./forgejo.nix
    ./vaultwarden.nix

    # CVE-2026-109618, CVE-2026-109619
    # ./nextcloud.nix

    # Kunny
    # ./freshrss.nix
  ];
}
