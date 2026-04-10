{ lib, config, ... }:
{
  programs.nixcord.quickCss = lib.optionalString config.catppuccin.enable ''
    /* ----- CATPPUCCIN THEME ----- */
    @import url("https://catppuccin.github.io/discord/dist/catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}.theme.css")
      (prefers-color-scheme: dark);
    @import url("https://catppuccin.github.io/discord/dist/catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}.theme.css")
      (prefers-color-scheme: light);
  '';
  programs.nixcord.config.enableReactDevtools = true;
  programs.nixcord.config.plugins = {
    betterNotesBox.enable = true;
    betterSessions.enable = true;
    consoleJanitor.disableSpotifyLogger = true;
    copyEmojiMarkdown.enable = true;
    messageLinkEmbeds.enable = true;
    # moreCommands.enable = true;
    # moreKaomoji.enable = true;
    reverseImageSearch.enable = true;
    roleColorEverywhere.enable = true;
    viewRaw.enable = true;
    ### utils
    appleMusicRichPresence = {
      enable = true;
      activityType = 2;
      enableTimestamps = true;
      enableButtons = true;
    };
  };
}
