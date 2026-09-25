{ pkgs, lib, ... }:
let
  video2gif = pkgs.writeShellApplication {
    name = "video2gif";
    runtimeInputs = with pkgs; [
      coreutils
      fd
      ffmpeg_8-full
      gifski
      parallel
    ];
    text = builtins.readFile ./scripts/video2gif.sh;
  };
  video2gifSimple = pkgs.writeShellApplication {
    name = "video2gif_simple";
    runtimeInputs = [ video2gif ];
    text = builtins.readFile ./scripts/video2gif_simple.sh;
  };

  editor = {
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
    ps = "procs";
    curl = "xh";
  };

  networking = {
    myip = lib.modules.mkForce "xh --body 'https://ipinfo.io/ip'";
    ports = "ss -tulanp";
    fastping = "ping -c 100 -i 0.2";
    listening = "ss -tlnp";
    netstat = "ss";
  };

  utility = {
    h = "history";
    j = "jobs -l";
    sha1 = lib.meta.getExe' pkgs.openssl "sha1";
    sha256 = lib.meta.getExe' pkgs.openssl "sha256";
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
    video2gif = lib.meta.getExe video2gif;
    video2gif_simple = lib.meta.getExe video2gifSimple;
  };

  darwin = lib.attrsets.optionalAttrs pkgs.stdenvNoCC.hostPlatform.isDarwin {
    micfix = "sudo killall coreaudiod";
    flushdns = "sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder";
  };

  linux = lib.attrsets.optionalAttrs pkgs.stdenvNoCC.hostPlatform.isLinux {
    pbcopy = "xclip -selection clipboard";
    pbpaste = "xclip -selection clipboard -o";
    open = "xdg-open";
  };

  aliases = editor // rustdogshit // networking // utility // git // scripts // darwin // linux;
in
{
  home.shellAliases = aliases;
}
