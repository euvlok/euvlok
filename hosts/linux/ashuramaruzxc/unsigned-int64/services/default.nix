_: {
  imports = [
    ### --- networking --- ###
    ./forgejo.nix
    ./nginx.nix
    ./tenjin-tls.nix
    ### --- networking --- ###

    ### --- utilities --- ###
    ./ecoflow.nix
    ./fail2ban.nix
    ./freshrss.nix
    ./grafana.nix
    ./msmtp.nix # email
    ./vaultwarden.nix
    ### --- utilities --- ###

    ### --- media --- ###
    ./anki.nix
    ./games.nix
    ./immich.nix
    ./jellyfin.nix
    ./nextcloud.nix
    ./torrent.nix
    ### --- media --- ###

    ### --- database --- ###
    ./postgresql.nix
    ./redis.nix
    ### --- database --- ###
  ];
}
