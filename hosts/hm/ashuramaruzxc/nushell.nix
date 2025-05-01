_: {
  programs.nushell.shellAliases = {
    arch = "distrobox enter arch";
    fastping = "ping -c 100";
    gpg-encrypt = "gpg -c --no-symkey-cache --cipher-algo=AES256";
    gpg-restart = "s";
    h = "history";
    j = "jobs -l";
    ports = "ss -tulanp";
    sha1 = "openssl sha1";
    uuid = "uuidgen -x | str to-upper";
  };
}
