{ paletteSource }:
{
  config,
  lib,
  pkgs,
  options,
  ...
}:
let
  webFileIcons = import ./web-file-icons.nix { inherit lib pkgs; };
  addons = pkgs.callPackage ../../../lib/firefox-addons.nix { };
  firefoxColor = pkgs.fetchurl {
    url = "https://addons.mozilla.org/firefox/downloads/file/3643624/firefox_color-2.1.7.xpi";
    hash = "sha256-t/sHtniPcjPdYiPngOGJtMe5VsJcQEk8KNcCBJMkkpI=";
  };

  theme = import ./firefox-theme.nix { inherit lib paletteSource; } {
    inherit (config.catppuccin) accent flavor;
  };

in
{
  config = lib.modules.mkIf config.catppuccin.enable (
    lib.modules.mkMerge [
      {
        # Generate the theme from palette data without importing generated files
        catppuccin = {
          firefox.enable = false;
          floorp.enable = false;
          librewolf.enable = false;
        };
      }
      (lib.attrsets.optionalAttrs (options.euvlok.home ? firefox) {
        euvlok.home.firefox.extraExtensions = [
          (addons.toTweezleExtension webFileIcons)
          {
            id = "FirefoxColor@mozilla.com";
            install_url = "file://${firefoxColor}";
            installation_mode = "normal_installed";
            updates_disabled = true;
          }
        ];
      })
      (lib.modules.mkMerge (
        map
          (
            name:
            let
              browser = config.programs.${name};
              profile = browser.profiles.default;
            in
            lib.modules.mkIf browser.enable {
              programs.${name}.profiles.default.settings."extensions.webextensions.ExtensionStorageIDB.enabled" =
                false;
              # Firefox Color uses local storage, which Tweezle's managed policies
              # cannot supply
              home.file."${browser.profilesPath}/${profile.path}/browser-extension-data/FirefoxColor@mozilla.com/storage.js" =
                {
                  force = true;
                  text = builtins.toJSON {
                    firstRunDone = true;
                    inherit theme;
                  };
                };
            }
          )
          [
            "firefox"
            "floorp"
            "librewolf"
          ]
      ))
    ]
  );
}
