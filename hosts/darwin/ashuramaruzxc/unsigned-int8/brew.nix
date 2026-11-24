{
  lib,
  config,
  pkgs,
  ...
}:
{
  nix-homebrew.taps."notprotonnot/homebrew-notproton" = pkgs.fetchFromGitHub {
    owner = "NotProtonNot";
    repo = "homebrew-notproton";
    rev = "38984e03ee25af380b9d0ddacfc47f8d5b04a27a";
    hash = "sha256-wcWjOKoTH4k26UmDie9hZgBC5u/i83uiHi48867bRQE=";
  };

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "uninstall";
    };
    caskArgs = {
      appdir = "/Applications";
      require_sha = false;
    };
    casks = [
      ### --- Socials --- ###
      "deltachat"
      "element" # halo based department?
      # "deltachat"
      ### --- Socials
      "cemu"
      "ppsspp-emulator"
      ### --- Gayming --- ###
      "dolphin"
      "notprotonnot/notproton/notproton"
      "steam" # Gayming
      "wine@devel"
      ### --- Gayming --- ###
      ### --- Graphics --- ###
      "affinity-designer" # Proffessional soyjak designer program
      "affinity-photo" # Proffessional soyjak drawing program
      "blender"
      "kdenlive"
      "krita"
      "obs"
      ### --- Graphics --- ###
      ### --- Utilities --- ###
      "forklift"
      "gstreamer-development"
      "gstreamer-runtime"
      "nextcloud-vfs"
      "stats"
      "yubico-authenticator"
      ### --- Utilities --- ###
      # Bro i need working widevine 😭
      "brave-browser"
    ];
    taps = lib.attrsets.attrNames config.nix-homebrew.taps;
  };
}
