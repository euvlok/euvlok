{
  pkgs,
  lib,
  config,
  osConfig ? null,
  ...
}:
let
  isLinux = pkgs.stdenvNoCC.hostPlatform.isLinux;

  extraSettings =
    lib.attrsets.optionalAttrs (isLinux && osConfig != null && osConfig.xdg.portal.xdgOpenUsePortal) {
      "widget.use-xdg-desktop-portal.file-picker" = 1;
    }
    //
      lib.attrsets.optionalAttrs
        (
          isLinux
          && osConfig != null
          && (osConfig.euvlok.nixos.nvidia.enable || osConfig.euvlok.nixos.amd.enable)
        )
        {
          "media.ffmpeg.vaapi.enabled" = true;
          "media.gpu-process.enabled" = true;
        }
    // lib.attrsets.optionalAttrs (isLinux && osConfig != null && osConfig.euvlok.nixos.nvidia.enable) {
      "media.hardware-video-decoding.force-enabled" = true;
      "media.rdd-ffmpeg.enabled" = true;
    };
in
{
  config = lib.modules.mkIf isLinux (
    lib.modules.mkMerge [
      (lib.modules.mkIf config.euvlok.home.firefox.firefox.enable {
        programs.firefox.profiles.default.settings = extraSettings;
      })
      (lib.modules.mkIf config.euvlok.home.firefox.floorp.enable {
        programs.floorp.profiles.default.settings = extraSettings;
      })
      (lib.modules.mkIf config.euvlok.home.firefox.librewolf.enable {
        programs.librewolf.profiles.default.settings = extraSettings;
      })
      (lib.modules.mkIf config.euvlok.home.firefox.zen-browser.enable {
        programs.zen-browser.profiles.default.settings = extraSettings;
      })
    ]
  );
}
