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
    rev = "886a488e75f621d3e993c9ce184c99a16c3c30fd";
    hash = "sha256-OIhXUMf61dNFy3kzAdwPBfnKcdfWJ1uVeGnDvsU+pUM=";
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
