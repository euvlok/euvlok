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
    rev = "f17a85b4f530e29544a4d92eac4715cd7e9f63e6";
    hash = "sha256-ssHdG/sp5gDyUB9VYAHOrcpNcfq+isOa+im6EeN4pPk=";
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
