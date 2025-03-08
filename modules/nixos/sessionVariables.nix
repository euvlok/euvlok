{ lib, config, ... }:
{
  environment.sessionVariables =
    {
      NIXOS_OZONE_WL = "1";

      MOZ_ENABLE_WAYLAND = "1";
      MOZ_USE_XINPUT2 = "1";

      # Compatibility for older Java GUI (AWT/Swing) apps
      _JAVA_AWT_WM_NONREPARENTING = "1";

      # Enable automatic scaling for Qt5/Qt6 applications based on monitor DPI
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";

      # Enable Variable Refresh Rate (VRR/G-Sync/FreeSync) for OpenGL and GLX
      __GL_VRR_ALLOWED = "1";
      __GLX_VRR_ALLOWED = "1";

      EGL_PLATFORM = "wayland";

      # Hardware cursors are currently broken on wlroots
      WLR_NO_HARDWARE_CURSORS = "1";
      WLR_DRM_NO_ATOMIC = "1";

      QT_QPA_PLATFORM = "wayland;xcb";
      QT_SCALE_FACTOR_ROUNDING_POLICY = "RoundPreferFloor";
    }
    // (lib.optionalAttrs
      (config.i18n.inputMethod.type == "fcitx5" && config.i18n.inputMethod.fcitx5.waylandFrontend)
      {
        SDL_IM_MODULE = "fcitx";
        GLFW_IM_MODULE = "ibus";
      }
    );
}
