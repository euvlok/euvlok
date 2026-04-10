{
  lib,
  config,
  ...
}:
{
  options.hm.nixcord.basePlugins.enable = lib.mkEnableOption "shared Nixcord plugin set" // {
    default = config.hm.nixcord.enable;
  };

  config = lib.mkIf config.hm.nixcord.basePlugins.enable {
    programs.nixcord.config.plugins = {
      alwaysExpandRoles.enable = true;
      betterGifPicker.enable = true;
      biggerStreamPreview.enable = true;
      disableCallIdle.enable = true;
      dontRoundMyTimestamps.enable = true;
      fixCodeblockGap.enable = true;
      forceOwnerCrown.enable = true;
      friendsSince.enable = true;
      serverInfo.enable = true;
      themeAttributes.enable = true;
      unlockedAvatarZoom.enable = true;
      vencordToolbox.enable = true;
      viewIcons.enable = true;
      messageLogger = {
        enable = true;
        collapseDeleted = true;
        ignoreSelf = true;
        ignoreBots = true;
      };
    };
  };
}
