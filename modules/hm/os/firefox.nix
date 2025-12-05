{
  pkgs,
  lib,
  config,
  osConfig,
  ...
}:
let
  isLinux = pkgs.stdenvNoCC.isLinux;

  extraSettings =
    lib.optionalAttrs (isLinux && osConfig.xdg.portal.xdgOpenUsePortal) {
      "widget.use-xdg-desktop-portal.file-picker" = 1;
    }
    // lib.optionalAttrs (isLinux && (osConfig.nixos.nvidia.enable || osConfig.nixos.amd.enable)) {
      "media.ffmpeg.vaapi.enabled" = true;
      "media.gpu-process.enabled" = true;
    }
    // lib.optionalAttrs (isLinux && osConfig.nixos.nvidia.enable) {
      "media.hardware-video-decoding.force-enabled" = true;
      "media.rdd-ffmpeg.enabled" = true;
    };
in
{
  config = lib.mkIf isLinux (
    lib.mkMerge [
      (lib.mkIf config.hm.firefox.firefox.enable {
        programs.firefox.profiles.default.settings = extraSettings;
      })
      (lib.mkIf config.hm.firefox.floorp.enable {
        programs.floorp.profiles.default.settings = extraSettings;
      })
      (lib.mkIf config.hm.firefox.librewolf.enable {
        programs.librewolf.profiles.default.settings = extraSettings;
      })
      (lib.mkIf config.hm.firefox.zen-browser.enable {
        programs.zen-browser.profiles.default.settings = extraSettings;
      })
    ]
  );
}
