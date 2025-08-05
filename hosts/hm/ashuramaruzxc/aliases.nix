{
  osConfig,
  pkgs,
  lib,
  ...
}:
let
  aliases = {
    video2gif = lib.getExe (pkgs.writeScriptBin "video2gif" (builtins.readFile ./scripts/video2gif.sh));
    # HELIX
    vi = "hx";
    vim = "hx";
    nvim = "hx";
    # Utils
    cat = "bat";
    df = "duf";
    diff = "delta";
    du = "dust";
    find = "fd";
    grep = "rg";
    htop = "btop";
    ps = "procs";
    bc = "bc -l";
    h = "history";
    j = "jobs -l";
    sha1 = lib.getExe' pkgs.openssl "sha1";
    uuid = "uuidgen -x | tr '[a-z]' '[A-Z]'";
    gpg-encrypt = "gpg -c --no-symkey-cache --cipher-algo=AES256";
    # Networking
    curl = "xh";
    ports = "ss -tulanp";
    fastping = "ping -c 100";
    # Misc
    neofetch = "fastfetch";
    myip = lib.mkForce "xh --body 'https://ipinfo.io/ip'";
  }
  // lib.optionalAttrs (osConfig.nixpkgs.hostPlatform.isDarwin) {
    micfix = "sudo killall coreaudiod";
  };
in
{
  programs.bash.shellAliases = aliases;
  programs.zsh.shellAliases = aliases;
}
