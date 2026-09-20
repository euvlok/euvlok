{ config, lib, ... }:
{
  system = {
    keyboard.enableKeyMapping = true;
    defaults.dock.tilesize = 42;
    stateVersion = 6;
    defaults.CustomUserPreferences = lib.modules.mkMerge [
      {
        NSGlobalDomain.AppleLanguages = [
          "en-US"
          "pl-PL"
          "uk-UA"
          "ru-RU"
          "ja-JP"
          "fr-FR"
        ];
      }
      (lib.modules.mkIf (lib.lists.elem "forklift" config.homebrew.casks) {
        NSGlobalDomain.NSFileViewer = "com.binarynights.ForkLift";
        "com.apple.LaunchServices/com.apple.launchservices.secure" = {
          LSHandlers = [
            {
              LSHandlerContentType = "public.folder";
              LSHandlerRoleAll = "com.binarynights.ForkLift";
            }
          ];
        };
      })
    ];
  };
}
