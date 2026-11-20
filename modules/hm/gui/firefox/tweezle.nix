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

  /**
    Check whether Tweezle can own the preferences of a Firefox profile

    # Inputs

    `profile`
    : Home Manager profile. Raw JavaScript in `preConfig` or `extraConfig`
      still needs Home Manager's `user.js` writer

    # Type
    ```
    managedPreferences :: AttrSet -> Bool
    ```

    # Examples
    :::{.example}
    ## `managedPreferences` usage example
    ```nix
    managedPreferences { preConfig = ""; extraConfig = ""; }
    => true
    ```
    :::
  */
  managedPreferences = profile: profile.preConfig == "" && profile.extraConfig == "";
  /**
    Convert Home Manager Firefox preferences into Tweezle's scalar settings

    # Inputs

    `profile`
    : A Home Manager Firefox profile with `bookmarks`, `extensions`, and
      `settings`. Explicit settings win over generated ones

    # Type
    ```
    preferences :: AttrSet -> AttrSet
    ```

    # Examples
    :::{.example}
    ## `preferences` usage example
    ```nix
    preferences {
      bookmarks.configFile = null;
      extensions.settings = { };
      settings."browser.example" = [ "test" ];
    }
    => { "browser.example" = ''["test"]''; }
    ```
    :::
  */
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
        /**
          Resolve the configured profile path without making it absolute

          # Inputs

          `profile`
          : The Home Manager profile, with a `path` relative to `cfg.profilesPath`

          # Type
          ```
          profileDir :: AttrSet -> String
          ```

          # Examples
          :::{.example}
          ## `profileDir` usage example
          ```nix
          profileDir { path = "work"; }
          => "${cfg.profilesPath}/work"
          ```
          :::
        */
        profileDir = profile: "${cfg.profilesPath}/${profile.path}";
        /**
          Resolve the absolute profile directory for Tweezle

          # Inputs

          `profile`
          : The Home Manager profile, with a `path` relative to `cfg.profilesPath`

          # Type
          ```
          absoluteProfileDir :: AttrSet -> String
          ```

          # Examples
          :::{.example}
          ## `absoluteProfileDir` usage example
          If the home directory is `/home/user` and `cfg.profilesPath` is
          `.mozilla/firefox`:
          ```nix
          absoluteProfileDir { path = "work"; }
          => "/home/user/.mozilla/firefox/work"
          ```
          :::
        */
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
                  launcher_name =
                    if package == null then name else lib.filesystem.baseNameOf (lib.meta.getExe package);
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
