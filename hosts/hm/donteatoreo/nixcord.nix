{ lib, config, ... }:
{
  programs.nixcord.quickCss = lib.optionalString config.catppuccin.enable ''
    /* ----- CATPPUCCIN THEME ----- */
    @import url("https://catppuccin.github.io/discord/dist/catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}.theme.css")
      (prefers-color-scheme: dark);
    @import url("https://catppuccin.github.io/discord/dist/catppuccin-frappe-${config.catppuccin.accent}.theme.css")
      (prefers-color-scheme: light);
  '';
  programs.nixcord.config.plugins = {
    alwaysExpandRoles.enable = true;
    betterGifPicker.enable = true;
    betterNotesBox.enable = true;
    betterSessions.enable = true;
    biggerStreamPreview.enable = true;
    blurNSFW.enable = true;
    clearURLs.enable = true;
    colorSighted.enable = true;
    dearrow.enable = true;
    disableCallIdle.enable = true;
    dontRoundMyTimestamps.enable = true;
    favoriteEmojiFirst.enable = true;
    fixCodeblockGap.enable = true;
    forceOwnerCrown.enable = true;
    friendsSince.enable = true;
    gifPaste.enable = true;
    greetStickerPicker.enable = true;
    hideAttachments.enable = true;
    imageZoom.enable = true;
    implicitRelationships.enable = true;
    memberCount.enable = true;
    messageLinkEmbeds.enable = true;
    messageLogger = {
      enable = true;
      collapseDeleted = true;
      ignoreSelf = true;
      ignoreBots = true;
    };
    moreUserTags.enable = true;
    newGuildSettings.enable = true;
    noBlockedMessages.enable = true;
    noMosaic.enable = true;
    noPendingCount.enable = true;
    noProfileThemes.enable = true;
    normalizeMessageLinks.enable = true;
    noRPC.enable = true;
    noTypingAnimation.enable = true;
    pauseInvitesForever.enable = true;
    permissionsViewer.enable = true;
    pictureInPicture.enable = true;
    platformIndicators.enable = true;
    previewMessage.enable = true;
    relationshipNotifier.enable = true;
    replyTimestamp.enable = true;
    revealAllSpoilers.enable = true;
    reverseImageSearch.enable = true;
    roleColorEverywhere.enable = true;
    serverInfo.enable = true;
    serverListIndicators.enable = true;
    shikiCodeblocks.enable = true;
    showConnections.enable = true;
    showHiddenThings.enable = true;
    showMeYourName.enable = true;
    showMeYourName.mode = "nick-user";
    showTimeoutDuration.enable = true;
    silentTyping.enable = true;
    startupTimings.enable = true;
    streamerModeOnStream.enable = true;
    superReactionTweaks.enable = true;
    textReplace.enable = true;
    themeAttributes.enable = true;
    typingIndicator.enable = true;
    typingTweaks.enable = true;
    unindent.enable = true;
    unlockedAvatarZoom.enable = true;
    userVoiceShow.enable = true;
    vencordToolbox.enable = true;
    viewIcons.enable = true;
    viewRaw.enable = true;
    voiceChatDoubleClick.enable = true;
    voiceMessages.enable = true;
  };
}
