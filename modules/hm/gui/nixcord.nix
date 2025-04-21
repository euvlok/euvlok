{
  inputs,
  pkgs,
  lib,
  config,
  osConfig,
  ...
}:
let
  # krisp-patcher ~/.config/discord/x.x.xx/modules/discord_krisp/discord_krisp.node
  #TODO: write a systemd service that will patch discord automatically assigned to: ashuramaruzxc
  krisp-patcher =
    pkgs.writers.writePython3Bin "krisp-patcher"
      {
        libraries = builtins.attrValues { inherit (pkgs.python3Packages) capstone pyelftools; };
        flakeIgnore = [
          "E501" # line too long (82 > 79 characters)
          "F403" # 'from module import *' used; unable to detect undefined names
          "F405" # name may be undefined, or defined from star imports: module
        ];
      }
      (
        builtins.readFile (
          pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/sersorrel/sys/afc85e6b249e5cd86a7bcf001b544019091b928c/hm/discord/krisp-patcher.py";
            sha256 = "sha256-h8Jjd9ZQBjtO3xbnYuxUsDctGEMFUB5hzR/QOQ71j/E=";
          }
        )
      );
in
{
  imports = [ inputs.nixcord.homeManagerModules.nixcord ];

  options.hm.nixcord.enable = lib.mkEnableOption "NixCord";

  config = lib.mkIf config.hm.nixcord.enable {
    home.packages = builtins.attrValues { inherit krisp-patcher; };
    programs.nixcord = {
      enable = true;
      discord.package = lib.mkIf (osConfig.nixpkgs.hostPlatform.isLinux) (
        inputs.nixpkgs-unstable.legacyPackages.${osConfig.nixpkgs.hostPlatform.system}.discord.overrideAttrs
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
