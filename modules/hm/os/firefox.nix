{
  pkgs,
  lib,
  config,
  options,
  osConfig ? null,
  ...
}:
let
  isLinux = pkgs.stdenvNoCC.hostPlatform.isLinux;
  nvidia = osConfig.euvlok.nixos.nvidia.enable or false;
  amd = osConfig.euvlok.nixos.amd.enable or false;
  browsers = builtins.filter (name: builtins.hasAttr name options.programs) [
    "firefox"
    "floorp"
    "librewolf"
    "zen-browser"
  ];

  extraSettings =
    lib.attrsets.optionalAttrs (isLinux && (osConfig.xdg.portal.xdgOpenUsePortal or false)) {
      "widget.use-xdg-desktop-portal.file-picker" = 1;
    }
    // lib.attrsets.optionalAttrs (isLinux && (nvidia || amd)) {
      "media.ffmpeg.vaapi.enabled" = true;
      "media.gpu-process.enabled" = true;
    }
    // lib.attrsets.optionalAttrs (isLinux && nvidia) {
      "media.hardware-video-decoding.force-enabled" = true;
      "media.rdd-ffmpeg.enabled" = true;
    };
in
{
  config = lib.modules.mkIf isLinux {
    programs = lib.attrsets.genAttrs browsers (
      name:
      lib.modules.mkIf config.programs.${name}.enable {
        profiles.default.settings = extraSettings;
      }
    );
  };
}
