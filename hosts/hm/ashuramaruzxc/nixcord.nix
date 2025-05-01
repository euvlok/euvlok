{ lib, config, ... }:
{
  programs.nixcord.quickCss = lib.optionalString config.catppuccin.enable ''
    /* ----- CATPPUCCIN THEME ----- */
    @import url("https://catppuccin.github.io/discord/dist/catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}.theme.css")
      (prefers-color-scheme: dark);
    @import url("https://catppuccin.github.io/discord/dist/catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}.theme.css")
      (prefers-color-scheme: light);
  '';
  programs.nixcord.config.plugins = {
    alwaysExpandRoles.enable = true;
    betterGifPicker.enable = true;
    betterNotesBox.enable = true;
    betterSessions.enable = true;
    biggerStreamPreview.enable = true;
    clearURLs.enable = true;
    consoleJanitor.disableSpotifyLogger = true;
    copyEmojiMarkdown.enable = true;
    disableCallIdle.enable = true;
    dontRoundMyTimestamps.enable = true;
    fixCodeblockGap.enable = true;
    forceOwnerCrown.enable = true;
    friendsSince.enable = true;
    messageLinkEmbeds.enable = true;
    moreCommands.enable = true;
    moreKaomoji.enable = true;
    reverseImageSearch.enable = true;
    roleColorEverywhere.enable = true;
    serverInfo.enable = true;
    textReplace.enable = true;
    themeAttributes.enable = true;
    unlockedAvatarZoom.enable = true;
    vencordToolbox.enable = true;
    viewIcons.enable = true;
    viewRaw.enable = true;
    messageLogger = {
      enable = true;
      collapseDeleted = true;
      ignoreSelf = true;
      ignoreBots = true;
    };
    ### utils
    appleMusicRichPresence = {
      enable = true;
      activityType = "listening";
      refreshInterval = 5;
      enableTimestamps = true;
      enableButtons = true;
    };
  };
}
