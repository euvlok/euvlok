{ pkgs, lib, ... }:
let
  mkScript = name: path: lib.getExe (pkgs.writeScriptBin name (builtins.readFile path));

  editor = {
    vi = "hx";
    vim = "hx";
    nvim = "hx";
    nano = "hx";
  };

  rustdogshit = {
    cat = "bat";
    df = "duf";
    diff = "delta";
    du = "dust";
    find = "fd";
    grep = "rg";
    htop = "btop";
    ps = "procs";
    curl = "xh";
    neofetch = "fastfetch";
  };

  networking = {
    myip = lib.mkForce "xh --body 'https://ipinfo.io/ip'";
    ports = "ss -tulanp";
    fastping = "ping -c 100 -i 0.2";
    listening = "ss -tlnp";
    netstat = "ss";
  };

  utility = {
    bc = "bc -l";
    h = "history";
    j = "jobs -l";
    sha1 = lib.getExe' pkgs.openssl "sha1";
    sha256 = lib.getExe' pkgs.openssl "sha256";
    uuid = "uuidgen -x | tr '[:lower:]' '[:upper:]'";
    gpg-encrypt = "gpg -c --no-symkey-cache --cipher-algo=AES256";
    gpg-decrypt = "gpg -d";
  };

  git = {
    g = "git";
    gs = "git status";
    ga = "git add";
    gc = "git commit";
    gp = "git push";
    gl = "git pull";
    gd = "git diff";
    gco = "git checkout";
    gb = "git branch";
    glog = "git log --oneline --graph --decorate";
  };

  scripts = {
    video2gif = mkScript "video2gif" ./scripts/video2gif.sh;
    video2gif_simple = mkScript "video2gif_simple" ./scripts/video2gif_simple.sh;
  };

  darwin = lib.optionalAttrs (pkgs.stdenvNoCC.isDarwin) {
    micfix = "sudo killall coreaudiod";
    flushdns = "sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder";
  };

  linux = lib.optionalAttrs (pkgs.stdenvNoCC.isLinux) {
    pbcopy = "xclip -selection clipboard";
    pbpaste = "xclip -selection clipboard -o";
    open = "xdg-open";
  };

  aliases = editor // rustdogshit // networking // utility // git // scripts // darwin // linux;
in
{
  programs.bash.shellAliases = aliases;
  programs.zsh.shellAliases = aliases;
}
