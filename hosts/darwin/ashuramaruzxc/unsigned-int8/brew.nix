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
    taps = [
      "cfergeau/crc"
    ];
    casks = [
      ### --- Socials --- ###
      "telegram" # telegram swift client
      "element" # halo based department?
      ### --- Socials
      ### --- Gayming --- ###
      "cemu"
      "crossover" # Supporting wine project
      "heroic"
      "mythic" # heroic but better
      "ppsspp-emulator"
      "steam" # Gayming
      "wine@devel"
      "xemu"
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
    ];
  };
}
