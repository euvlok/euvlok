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
      no_quarantine = true;
      require_sha = false;
    };
    casks = [
      ### --- Socials --- ###
      "telegram" # telegram swift client
      "element" # halo based department?
      ### --- Socials
      "cemu"
      "ppsspp-emulator"
      ### --- Gayming --- ###
      "crossover" # Supporting wine project
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
