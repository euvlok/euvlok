{ lib, config, ... }:
{
  programs.nixcord.quickCss = lib.optionalString config.catppuccin.enable ''
    /* ----- CATPPUCCIN THEME ----- */
    @import url("https://catppuccin.github.io/discord/dist/catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}.theme.css")
      (prefers-color-scheme: dark);
    @import url("https://catppuccin.github.io/discord/dist/catppuccin-frappe-${config.catppuccin.accent}.theme.css")
      (prefers-color-scheme: light);
  '';
  programs.nixcord.config = {
    useQuickCss = true;
    plugins = {
      alwaysExpandRoles.enable = true;
      betterGifPicker.enable = true;
      biggerStreamPreview.enable = true;
      blurNsfw.enable = true;
      clearUrLs.enable = true;
      disableCallIdle.enable = true;
      dontRoundMyTimestamps.enable = true;
      fixCodeblockGap.enable = true;
      fixImagesQuality.enable = true;
      forceOwnerCrown.enable = true;
      friendsSince.enable = true;
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
      imageZoom.enable = true;
      implicitRelationships.enable = true;
      memberCount.enable = true;
      messageLogger = {
        enable = true;
        collapseDeleted = true;
        ignoreSelf = true;
        ignoreBots = true;
      };
      newGuildSettings.enable = true;
      noBlockedMessages.enable = true;
      noMaskedUrlPaste.enable = true;
      noMosaic.enable = true;
      noPendingCount.enable = true;
      noProfileThemes.enable = true;
      noRpc.enable = true;
      noTypingAnimation.enable = true;
      normalizeMessageLinks.enable = true;
      pauseInvitesForever.enable = true;
      pictureInPicture.enable = true;
      platformIndicators.enable = true;
      previewMessage.enable = true;
      relationshipNotifier.enable = true;
      replyTimestamp.enable = true;
      revealAllSpoilers.enable = true;
      serverInfo.enable = true;
      serverListIndicators.enable = true;
      showConnections.enable = true;
      showHiddenThings.enable = true;
      showTimeoutDuration.enable = true;
      silentTyping.enable = true;
      streamerModeOnStream.enable = true;
      themeAttributes.enable = true;
      typingIndicator.enable = true;
      typingTweaks.enable = true;
      unindent.enable = true;
      unlockedAvatarZoom.enable = true;
      userVoiceShow.enable = true;
      vencordToolbox.enable = true;
      viewIcons.enable = true;
      voiceChatDoubleClick.enable = true;
    };
  };
}
