{
  pkgs,
  inputs,
  ...
}:
{
  imports = [ inputs.spicetify-nix.homeManagerModules.default ];
  programs.spicetify.enable = true;
  programs.spicetify.enabledExtensions = builtins.attrValues {
    inherit (inputs.spicetify-nix.legacyPackages.${pkgs.system}.extensions)
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
}
