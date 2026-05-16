{
  pkgs,
  inputs,
  lib,
  ...
}:
{
  imports = [ inputs.spicetify-nix-trivial.homeManagerModules.default ];
  programs.spicetify = lib.modules.mkIf (pkgs.stdenv.hostPlatform.system != "aarch64-linux") {
    enable = true;
    enabledExtensions = builtins.attrValues {
      inherit (inputs.spicetify-nix-trivial.legacyPackages.${pkgs.system}.extensions)
        adblock
        beautifulLyrics # Apple Music like Lyrics
        copyLyrics
        fullAlbumDate
        shuffle # Shuffle properly, using Fisher-Yates with zero bias
        aiBandBlocker
        catJamSynced
        betterGenres
        powerBar
        ;
    };
  };
}
