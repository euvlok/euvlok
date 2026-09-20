{ lib, config, ... }:
{
  options.euvlok.nixos.gui.wlrootsWorkarounds =
    lib.options.mkEnableOption "wlroots hardware cursor and atomic mode workarounds"
    // {
      default = true;
    };

  config = lib.modules.mkIf config.euvlok.nixos.gui.enable {
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";

      MOZ_ENABLE_WAYLAND = "1";
      MOZ_USE_XINPUT2 = "1";

      # Compatibility for older Java GUI (AWT/Swing) apps
      _JAVA_AWT_WM_NONREPARENTING = "1";

      # Enable automatic scaling for Qt5/Qt6 applications based on monitor DPI
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";

      EGL_PLATFORM = "wayland";

      QT_QPA_PLATFORM = "wayland;xcb";
      QT_SCALE_FACTOR_ROUNDING_POLICY = "RoundPreferFloor";
    }
    // (lib.attrsets.optionalAttrs
      (config.i18n.inputMethod.type == "fcitx5" && config.i18n.inputMethod.fcitx5.waylandFrontend)
      {
        SDL_IM_MODULE = "fcitx";
        GLFW_IM_MODULE = "ibus";
      }
    )
    // (lib.attrsets.optionalAttrs config.euvlok.nixos.gui.wlrootsWorkarounds {
      # Hardware cursor and atomic mode escape hatches for wlroots compositors.
      WLR_NO_HARDWARE_CURSORS = "1";
      WLR_DRM_NO_ATOMIC = "1";
    })
    // {
      GSK_RENDERER = "vulkan";
      QSG_RHI_BACKEND = "vulkan";
    };
  };
}
