_: {
  programs.nushell.shellAliases = {
    ports = "ss -tulanp";
    gpg-encrypt = "gpg -c --no-symkey-cache --cipher-algo=AES256";
    gpg-restart = "gpg-connect-agent updatestartuptty /bye > /dev/null";
    uuid = "uuidgen -x | str to-upper";
    grep = "grep --color=auto";
    sha1 = "openssl sha1";
    bc = "bc -l";
    diff = "colordiff";
    hm = "home-manager";
    hist = "history";
    h = "history";
    j = "jobs -l";
    fastping = "ping -c 100";
    ytmp4 = "yt-dlp -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best'";
    arch = "distrobox enter arch";
    void = "distrbox enter void";
    gentoo = "distrobox enter gentoo";
    s = "sudo";
    vms = "nixos-build-vms";
    buildvm = "nixos-rebuild build-vm";
    buildvm_ = "nixos-rebuild build-vm-with-bootloader";
  };
}
