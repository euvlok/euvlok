{ config, lib, ... }:
{
  system = {
    keyboard.enableKeyMapping = true;
    defaults.dock.tilesize = 42;
    stateVersion = 6;
    defaults.CustomUserPreferences = lib.mkIf (builtins.elem "forklift" config.homebrew.casks) {
      NSGlobalDomain.NSFileViewer = "com.binarynights.ForkLift";
      "com.apple.LaunchServices/com.apple.launchservices.secure" = {
        LSHandlers = [
          {
            LSHandlerContentType = "public.folder";
            LSHandlerRoleAll = "com.binarynights.ForkLift";
          }
        ];
      };
    };
  };
}
