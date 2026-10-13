{
  config,
  lib,
  pkgs,
  ...
}:
let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  platform = if isDarwin then "macos" else "linux";
  browsers = {
    firefox = {
      variant = "firefox";
      appName = "Firefox";
    };
    floorp = {
      variant = "floorp";
      appName = "Floorp";
    };
    librewolf = {
      variant = "librewolf";
      appName = "LibreWolf";
    };
    zen-browser = {
      variant = "zen";
      appName = "Zen Browser (Twilight)";
    };
  };

  # Raw JavaScript still needs Home Manager's user.js writer
  managedPreferences = profile: profile.preConfig == "" && profile.extraConfig == "";
  preferences =
    profile:
    lib.attrsets.mapAttrs
      (
        _: value:
        if lib.filesystem.isPath value then
          toString value
        else if lib.trivial.isBool value || lib.trivial.isInt value || lib.strings.isString value then
          value
        else
          lib.strings.toJSON value
      )
      (
        lib.attrsets.optionalAttrs (profile.bookmarks.configFile != null) {
          "browser.bookmarks.file" = toString profile.bookmarks.configFile;
          "browser.places.importBookmarksHTML" = true;
        }
        //
          lib.attrsets.optionalAttrs
            (lib.lists.any (extension: extension.settings != { }) (
              lib.attrsets.attrValues profile.extensions.settings
            ))
            {
              "extensions.webextensions.ExtensionStorageIDB.enabled" = false;
            }
        // profile.settings
      );
in
{
  config = lib.modules.mkMerge (
    lib.attrsets.mapAttrsToList (
      name: browser:
      let
        cfg = config.programs.${name};
        package = cfg.finalPackage;
        profileDir = profile: "${cfg.profilesPath}/${profile.path}";
        absoluteProfileDir =
          profile:
          let
            path = profileDir profile;
          in
          if lib.strings.hasPrefix "/" path then path else "${config.home.homeDirectory}/${path}";
      in
      lib.modules.mkIf cfg.enable {
        programs.tweezle = {
          enable = true;
          configurations = lib.attrsets.mapAttrs' (
            profileName: profile:
            lib.attrsets.nameValuePair "${name}-${profileName}" {
              firefox = {
                inherit (browser) variant;
                executable_name = "${name}-${profileName}-configured";
                paths.${platform}.profile_dir = absoluteProfileDir profile;
                preferences = lib.modules.mkIf (managedPreferences profile) (preferences profile);
              }
              // lib.attrsets.optionalAttrs (!isDarwin) {
                linux = {
                  app_dir = if package == null then "${config.home.profileDirectory}/bin" else "${package}/bin";
                  launcher_name = if package == null then name else baseNameOf (lib.meta.getExe package);
                };
              }
              // lib.attrsets.optionalAttrs isDarwin {
                macos = {
                  app_dir =
                    if package == null then
                      "/Applications/${browser.appName}.app"
                    else
                      "${package}/Applications/${package.applicationName or browser.appName}.app";
                  launcher_path = "Contents/MacOS/${if name == "zen-browser" then "zen" else browser.variant}";
                };
              };
            }
          ) cfg.profiles;
        };

        # Home Manager registers profiles; Tweezle writes their preferences
        home.file = lib.attrsets.mapAttrs' (
          _: profile:
          lib.attrsets.nameValuePair "${profileDir profile}/user.js" {
            enable = lib.modules.mkIf (managedPreferences profile) (lib.modules.mkForce false);
          }
        ) cfg.profiles;
      }
    ) browsers
  );
}
