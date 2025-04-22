_: {
  imports = [
    # Most important
    ./nginx.nix
    ./grafana.nix

    # utils
    ./fail2ban.nix
    ./msmtp.nix # email

    # media
    ./torrent.nix
    ./jellyfin.nix
    ./anki.nix

    # db
    ./postgresql.nix
    ./redis.nix

    # Misc
    ./vaultwarden.nix
    ./nextcloud.nix
    ./cvat.nix
  ];
}
