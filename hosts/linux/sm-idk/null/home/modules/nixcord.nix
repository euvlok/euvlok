{ pkgs, ... }:
{
  programs.nixcord = {
    enable = true;

    # Use Equibop (native ARM64 Discord client)
    equibop.enable = true;
    equibop.package = pkgs.unstable.equibop;

    # Disable official Discord (not available on aarch64)
    discord.enable = false;

    config = {
      frameless = false;
      autoUpdateNotification = true;

      plugins = {
        toastNotifications = {
          enable = true;
          friendServerNotifications = true;
          maxNotifications = 3.0;
          directMessages = true;
          groupMessages = true;
        };
        # VCSupport.enable = true;
        webpackTarball = {
          enable = true;
          patched = true;
        };
        equicordHelper = {
          enable = true;
        };
        disableDeepLinks.enable = true;
        webContextMenus.enable = true;
        # friendCloud.enable = true;
        saveFavoriteGifs.enable = true;
        betterCommands = {
          enable = true;
          autoFillArguments = true;
          allowNewlinesInCommands = true;
        };
        # arRPCBun.enable = true;
        ghosted = {
          enable = true;
          showDmIcons = true;
        };
        alwaysTrust = {
          enable = true;
          domain = true;
          file = true;
          noDeleteSafety = true;
        };
        betterSettings = {
          enable = true;
          disableFade = true;
          eagerLoad = true;
          organizeMenu = true;
        };
        clearUrls.enable = true;
        consoleJanitor = {
          enable = true;
          disableSpotifyLogger = true;
          whitelistedLoggers = "GatewaySocket; Routing/Utils";
        };
        crashHandler.enable = true;
        dearrow = {
          enable = true;
          replaceElements = 0;
          dearrowByDefault = true;
        };
        fakeNitro = {
          enable = true;
          enableStickerBypass = true;
          enableStreamQualityBypass = true;
          enableEmojiBypass = true;
          transformEmojis = true;
          transformStickers = true;
          stickerSize = 160.0;
          hyperLinkText = "{{NAME}}";
          useStickerHyperLinks = true;
        };
        newPluginsManager.enable = true;
        # noModalAnimation.enable = true;
        noNitroUpsell.enable = true;
        # polishWording = {
        #   enable = true;
        #   fixApostrophes = true;
        #   fixCapitalization = true;
        #   fixPunctuation = true;
        #   fixPunctuationFrequency = 100.0;
        # };
        favoriteGifSearch = {
          enable = true;
          searchOption = "hostandpath";
        };
        noTypingAnimation.enable = true;
        platformIndicators = {
          enable = true;
          colorMobileIndicator = true;
          list = true;
          profiles = true;
          messages = true;
          consoleIcon = "equicord";
        };
        relationshipNotifier = {
          enable = true;
          offlineRemovals = true;
          groups = true;
          servers = true;
          friends = true;
          friendRequestCancels = true;
        };
        replaceGoogleSearch = {
          enable = true;
          customEngineURL = "https://duckduckgo.com/?=";
        };
        spotifyCrack = {
          enable = true;
          noSpotifyAutoPause = true;
        };
        webKeybinds.enable = true;
        webScreenShareFixes.enable = true;
        youtubeAdblock.enable = true;
        # anammox = {
        #   enable = true;
        #   dms = true;
        #   billing = true;
        #   gift = true;
        #   emojiList = true;
        #   serverBoost = true;
        # };
        equicordToolbox.enable = true;
        # gifRoulette.enable = true;
      };
    };
  };

  # Ensure desktop entries are available
  xdg.dataFile = {
    "applications/equibop.desktop".text = ''
      [Desktop Entry]
      Categories=Network;InstantMessaging;Chat
      Exec=equibop %U
      GenericName=Internet Messenger
      Icon=equibop
      Keywords=discord;equibop;electron;chat
      Name=Equibop
      StartupWMClass=Equibop
      Type=Application
      Version=1.5
    '';
  };
}
