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
      "steam" # Gayming
      ### --- Gayming --- ###

      ### --- Graphics --- ###
      "obs"
      ### --- Graphics --- ###
      ### --- Utilities --- ###
      "shottr"
      "forklift"
      "nextcloud-vfs"
      ### --- Utilities --- ###
    ];
  };
}
