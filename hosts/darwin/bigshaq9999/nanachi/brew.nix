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
      appdir = "${config.users.users.faputa.home}/Applications";
      no_quarantine = true;
      require_sha = false;
    };
    taps = [
      "cfergeau/crc"
    ];
    casks = [
      ### --- Socials --- ###
      "telegram" # telegram swift client
      # "element" # halo cringe department?
      ### --- Socials
      ### --- Gayming --- ###
      "crossover" # Supporting wine project
      "steam" # Gayming
      ### --- Gayming --- ###
      ### --- Graphics --- ###
      # "kdenlive"
      "obs"
      ### --- Graphics --- ###
      ### --- Utilities --- ###
      "finetine"
      "forklift"
      "nextcloud-vfs"
      "qspace-pro"
      ### --- Utilities --- ###
      "mullvad-vpn"
    ];
  };
}
