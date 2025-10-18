_: {
  programs.nixcord.config.enableReactDevtools = true;
  programs.nixcord.config.plugins = {
    betterGifPicker.enable = true;
    clearURLs.enable = true;
    consoleJanitor.disableSpotifyLogger = true;
    fixCodeblockGap.enable = true;
    forceOwnerCrown.enable = true;
    messageLogger = {
      enable = true;
      collapseDeleted = true;
      ignoreSelf = true;
      ignoreBots = true;
    };
    callTimer.enable = true;
    expressionCloner.enable = true;
    imageZoom.enable = true;
    implicitRelationships.enable = true;
    noMosaic.enable = true;
    noOnboardingDelay.enable = true;
    noTypingAnimation.enable = true;
    openInApp.enable = true;
    serverInfo.enable = true;
    showHiddenChannels.enable = true;
    spotifyCrack.enable = true;
    silentTyping.enable = true;
    whoReacted.enable = true;
    colorSighted.enable = true;
    messageClickActions.enable = true;
  };
  programs.nixcord.config.themeLinks = [
    "https://raw.githubusercontent.com/DiscordStyles/HorizontalServerList/deploy/HorizontalServerList.theme.css"
  ];
}
