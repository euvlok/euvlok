{
  inputs,
  pkgs,
  lib,
  config,
  osConfig,
  ...
}:
{
  imports = [ inputs.nixcord-trivial.homeModules.nixcord ];

  options.hm.nixcord.enable = lib.mkEnableOption "Nixcord";

  config = lib.mkIf config.hm.nixcord.enable {
    programs.nixcord = {
      enable = true;
      discord.package = lib.mkIf (osConfig.nixpkgs.hostPlatform.isLinux) (
        inputs.nixcord-trivial.packages.${osConfig.nixpkgs.hostPlatform.system}.discord.overrideAttrs
          (oldAttrs: {
            installPhase =
              oldAttrs.installPhase
              + ''wrapProgramShell "$out/opt/Discord/Discord" --add-flags "--enable-wayland-ime --wayland-text-input-version=3"'';
          })
      );
      discord.vencord.unstable = true;
      discord.openASAR.enable = false;
      config = {
        useQuickCss = true;
        plugins = {
          betterSettings.enable = true;
          betterUploadButton.enable = true;
          callTimer = {
            enable = true;
            format = "human";
          };
          consoleJanitor.disableNoisyLoggers = true;
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
          noMaskedUrlPaste.enable = true;
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
    };
  };
}
