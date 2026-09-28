{ config, ... }:
{
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
      ### --- Gay --- ###
      "notion"
      "stats"
      ### --- Gay --- ###
      ### --- Socials --- ###
      "deltachat"
      "element" # halo based department?
      # "deltachat"
      ### --- Socials
      "cemu"
      "ppsspp-emulator"
      ### --- Gayming --- ###
      "crossover" # Supporting wine project
      "dolphin"
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
      "yubico-authenticator"
      ### --- Utilities --- ###
      # Bro i need working widevine 😭
      "brave-browser"
    ];
    taps = builtins.attrNames config.nix-homebrew.taps;
  };
}
