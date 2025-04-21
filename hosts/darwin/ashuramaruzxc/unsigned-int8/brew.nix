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
      "homebrew/cask-versions"
      "cfergeau/crc"
    ];
    casks = [
      ### --- Socials --- ###
      "telegram" # telegram swift client
      "element" # halo based department?
      ### --- Socials
      ### --- Gayming --- ###
      "crossover" # Supporting wine project
      "whisky" # just for the wine
      "mythic" # heroic but better
      "heroic"
      "steam" # Gayming
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
      "nextcloud"
      "yubico-authenticator"
      ### --- Utilities --- ###
    ];
  };
}
