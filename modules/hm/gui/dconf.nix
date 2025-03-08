{
  pkgs,
  lib,
  osConfig,
  ...
}:
{
  dconf.settings."org/gnome" =
    {
      "shell/app-switcher".current-workspace-only = false;

      "desktop/interface" = {
        clock-show-date = true;
        clock-show-seconds = true;
      };

      "desktop/wm/preferences".resize-with-right-button = true;
    }
    // lib.optionalAttrs (osConfig.services.xserver.gnome.enable) {
      "shell" = {
        enabled-extensions =
          let
            packages = osConfig.environment.systemPackages;
          in
          [
            "places-menu@gnome-shell-extensions.gcampax.github.com"
            "light-style@gnome-shell-extensions.gcampax.github.com"
          ]
          ++ (lib.optionals (lib.any (pkg: pkg == pkgs.gnomeExtensions.appindicator) (packages)) [
            "appindicatorsupport@rgcjonas.gmail.com"
          ])
          ++ (lib.optionals (lib.any (pkg: pkg == pkgs.gnomeExtensions.clipboard-history) (packages)) [
            "clipboard-indicator@tudmotu.com"
          ])
          ++ (lib.optionals (lib.any (pkg: pkg == pkgs.gnomeExtensions.system-monitor) (packages)) [
            "system-monitor@gnome-shell-extensions.gcampax.github.com"
          ]);
      };
    };
}
