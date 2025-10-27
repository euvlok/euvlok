{
  pkgs,
  inputs,
  lib,
  config,
  ...
}:
{
  imports = [ inputs.nixcord-trivial.homeModules.nixcord ];

  options.hm.nixcord.enable = lib.mkEnableOption "Nixcord";

  config = lib.mkIf config.hm.nixcord.enable {
    assertions = [
      {
        assertion = pkgs.stdenvNoCC.isx86 || pkgs.stdenvNoCC.isDarwin;
        message = "You cannot use Nixcord (Discord) on aarch64-linux";
      }
    ];
    programs.nixcord = {
      enable = true;
      discord.vencord.unstable = true;
      discord.openASAR.enable = false;
      config.useQuickCss = true;
    };
    programs.nixcord.config.plugins = {
      betterSettings.enable = true;
      betterUploadButton.enable = true;
      callTimer = {
        enable = true;
        format = "human";
      };
      consoleJanitor.enable = true;
      crashHandler.enable = true;
      fakeNitro.enable = true;
      favoriteEmojiFirst.enable = true;
      fixSpotifyEmbeds.enable = true;
      fixYoutubeEmbeds.enable = true;
      fullSearchContext.enable = true;
      mutualGroupDMs.enable = true;
      noDevtoolsWarning.enable = true;
      noF1.enable = true;
      noUnblockToJump.enable = true;
      onePingPerDM.enable = true;
      readAllNotificationsButton.enable = true;
      textReplace.enable = true;
      textReplace.regexRules = [
        {
          find = "https?:\\/\\/(www\\.)?instagram\\.com\\/[^\\/]+\\/(p|reel)\\/([A-Za-z0-9-_]+)\\/?";
          replace = "https://g.ddinstagram.com/$2/$3";
        }
        {
          find = "https:\\/\\/x\\.com\\/([^\\/]+\\/status\\/[0-9]+)";
          replace = "https://vxtwitter.com/$1";
        }
        {
          find = "https:\\/\\/twitter\\.com\\/([^\\/]+\\/status\\/[0-9]+)";
          replace = "https://vxtwitter.com/$1";
        }
        {
          find = "https:\\/\\/(www\\.)?tiktok\\.com\\/(.*)";
          replace = "https://vxtiktok.com/$2";
        }
        {
          find = "https:\\/\\/(www\\.|old\\.)?reddit\\.com\\/(r\\/[a-zA-Z0-9_]+\\/comments\\/[a-zA-Z0-9_]+\\/[^\\s]*)";
          replace = "https://vxreddit.com/$2";
        }
        {
          find = "https:\\/\\/(www\\.)?pixiv\\.net\\/(.*)";
          replace = "https://phixiv.net/$2";
        }
        {
          find = "https:\\/\\/(?:www\\.|m\\.)?twitch\\.tv\\/twitch\\/clip\\/(.*)";
          replace = "https://clips.fxtwitch.tv/$1";
        }
        {
          find = "https:\\/\\/(?:www\\.)?youtube\\.com\\/(?:watch\\?v=|shorts\\/)([a-zA-Z0-9_-]+)";
          replace = "https://youtu.be/$1";
        }
      ];
      translate.enable = true;
      validReply.enable = true;
      validUser.enable = true;
      volumeBooster.enable = true;
      webScreenShareFixes.enable = true;
      youtubeAdblock.enable = true;
    };
  };
}
