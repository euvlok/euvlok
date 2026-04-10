{ config, ... }:
{
  programs.nixcord.quickCss = ''
    /* ----- CATPPUCCIN THEME ----- */
    @import url("https://catppuccin.github.io/discord/dist/${config.catppuccin.flavor}-${config.catppuccin.accent}.css")
    (prefers-color-scheme: dark);
    @import url("https://catppuccin.github.io/discord/dist/${config.catppuccin.accent}.css")
    (prefers-color-scheme: light);
  '';
  programs.nixcord.config.plugins = {
    ClearURLs.enable = true;
    fixImagesQuality.enable = true;
    gifPaste.enable = true;
    greetStickerPicker.enable = true;
    hideMedia.enable = true;
    ignoreActivities = {
      enable = true;
      ignorePlaying = true;
      ignoreListening = true;
      ignoreWatching = true;
      ignoreCompeting = true;
    };
    implicitRelationships.enable = true;
    memberCount.enable = true;
    newGuildSettings.enable = true;
    noBlockedMessages.enable = true;
    noMaskedUrlPaste.enable = true;
    noMosaic.enable = true;
    noPendingCount.enable = true;
    noProfileThemes.enable = true;
    noTypingAnimation.enable = true;
    pauseInvitesForever.enable = true;
    pictureInPicture.enable = true;
    platformIndicators.enable = true;
    previewMessage.enable = true;
    relationshipNotifier.enable = true;
    replyTimestamp.enable = true;
    revealAllSpoilers.enable = true;
    serverListIndicators.enable = true;
    showConnections.enable = true;
    showHiddenThings.enable = true;
    showTimeoutDuration.enable = true;
    silentTyping.enable = true;
    streamerModeOnStream.enable = true;
    typingIndicator.enable = true;
    typingTweaks.enable = true;
    unindent.enable = true;
    userVoiceShow.enable = true;
    voiceChatDoubleClick.enable = true;
  };
}
