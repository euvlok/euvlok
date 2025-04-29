_: {
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
      require_sha = true;
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
      "crossover" # Supporting wine project
      "mythic" # heroic but better
      "heroic"
      # "steam" # Gayming
      "xemu"
      "ppsspp"
      "cemu"
      ### --- Gayming --- ###
      ### --- Graphics --- ###
      "blender"
      "krita"
      "kdenlive"
      "obs"
      "affinity-photo" # Proffessional soyjak drawing program
      "affinity-designer" # Proffessional soyjak designer program
      ### --- Graphics --- ###
      ### --- Utilities --- ###
      "shottr"
      "forklift"
      "nextcloud-vfs"
      "yubico-authenticator"
      ### --- Utilities --- ###
    ];
  };
}
