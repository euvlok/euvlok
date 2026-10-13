{ euvlokInputs }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.euvlok.home.firefox;
  unbrandedFirefox = pkgs.callPackage ../../../../lib/firefox-unbranded/firefox-unbranded.nix { };
  addons = pkgs.callPackage ../../../../lib/firefox-addons.nix { };
  extensionType = lib.types.submodule {
    freeformType = (pkgs.formats.json { }).type;
    options.id = lib.options.mkOption {
      type = lib.types.nonEmptyStr;
      description = "The Firefox add-on ID";
    };
  };
  browserNames = [
    "firefox"
    "floorp"
    "librewolf"
    "zen-browser"
  ];
  default = {
    search = {
      force = true;
      default = config.euvlok.home.firefox.defaultSearchEngine;
      privateDefault = config.euvlok.home.firefox.defaultSearchEngine;
      order = [
        "google"
        "kagi"
        "Nix Packages"
        "GitHub"
        "youtube"
      ];
      engines = {
        "ddg" = {
          urls = [
            {
              template = "https://duckduckgo.com/";
              params = [
                {
                  name = "q";
                  value = "{searchTerms}";
                }
              ];
            }
          ];
          iconMapObj."16" = "https://duckduckgo.com/favicon.ico";
          definedAliases = [ "@ddg" ];
        };
        "GitHub" = {
          urls = [
            {
              template = "https://github.com/search";
              params = [
                {
                  name = "q";
                  value = "{searchTerms}";
                }
              ];
            }
          ];
          iconMapObj."16" = "https://github.com/favicon.ico";
          definedAliases = [ "@gh" ];
        };
        "google".metaData.alias = "@g"; # builtin engines only support specifying one additional alias
        "kagi" = {
          urls = [
            {
              template = "https://kagi.com/search";
              params = [
                {
                  name = "q";
                  value = "{searchTerms}";
                }
              ];
            }
            {
              template = "https://kagi.com/api/autosuggest";
              params = [
                {
                  name = "q";
                  value = "{searchTerms}";
                }
              ];
              type = "application/x-suggestions+json";
            }
          ];
          iconMapObj."16" = "https://kagi.com/favicon.ico";
          definedAliases = [ "@kagi" ];
        };
        "NixOS Wiki" = {
          urls = [
            {
              template = "https://nixos.wiki/index.php";
              params = [
                {
                  name = "search";
                  value = "{searchTerms}";
                }
              ];
            }
          ];
          iconMapObj."16" = "https://wiki.nixos.org/favicon.ico";
          definedAliases = [ "@nw" ];
        };
        "Nix Packages" = {
          urls = [
            {
              template = "https://search.nixos.org/packages";
              params = [
                {
                  name = "channel";
                  value = "unstable";
                }
                {
                  name = "query";
                  value = "{searchTerms}";
                }
              ];
            }
          ];
          icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
          definedAliases = [ "@np" ];
        };
        "Nix Options" = {
          urls = [
            {
              template = "https://search.nixos.org/options";
              params = [
                {
                  name = "type";
                  value = "options";
                }
                {
                  name = "query";
                  value = "{searchTerms}";
                }
                {
                  name = "channel";
                  value = "unstable";
                }
              ];
            }
          ];
          icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
          definedAliases = [ "@nq" ];
        };
        "Home Manager" = {
          urls = [
            {
              template = "https://home-manager-options.extranix.com";
              params = [
                {
                  name = "query";
                  value = "{searchTerms}";
                }
                {
                  name = "release";
                  value = "master";
                }
              ];
            }
          ];
          icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
          definedAliases = [ "@hm" ];
        };
        "youtube" = {
          urls = [
            {
              template = "https://www.youtube.com/results";
              params = [
                {
                  name = "search_query";
                  value = "{searchTerms}";
                }
              ];
            }
          ];
          iconMapObj."16" = "https://youtube.com/favicon.ico";
          definedAliases = [ "@yt" ];
        };
      };
    };
    isDefault = true;
    settings = {
      "browser.urlbar.suggest.calculator" = true;
      "browser.urlbar.update2.engineAliasRefresh" = true;
      "xpinstall.signatures.required" = false;
    }
    // lib.attrsets.optionalAttrs (config.euvlok.home.firefox.acceptedLanguages != [ ]) {
      "intl.accept_languages" =
        lib.strings.concatStringsSep "," config.euvlok.home.firefox.acceptedLanguages;
    };
  };
  policies = {
    DisableAppUpdate = true;
    DisableTelemetry = true;
    OfferToSaveLogins = false;
    OfferToSaveLoginsDefault = false;
    NoDefaultBookmarks = true;
    DisableFeedbackCommands = true;
    DisableFirefoxStudies = true;
    DisableMasterPasswordCreation = true;
    DisablePocket = true;
    DisableSetDesktopBackground = true;
  };
in
{
  imports = [
    euvlokInputs.tweezle.homeModules.default
    (lib.modules.importApply ./zen-browser.nix { inherit euvlokInputs; })
    (lib.modules.importApply ./extension-policies.nix { inherit euvlokInputs; })
    ./tweezle.nix
  ];

  options.euvlok.home.firefox = {
    enable = lib.options.mkEnableOption "declarative Firefox-based browsers";
    extraExtensions = lib.options.mkOption {
      type = lib.types.listOf extensionType;
      default = [ ];
      description = "Additional Tweezle extension declarations for every enabled Firefox-family browser";
    };
    defaultSearchEngine = lib.options.mkOption {
      default = "google";
      description = "Search engine used by default in normal and private windows.";
      example = "kagi";
      type = lib.types.enum [
        "ddg"
        "google"
        "kagi"
      ];
    };
    acceptedLanguages = lib.options.mkOption {
      type = lib.types.listOf lib.types.nonEmptyStr;
      default = [ ];
      description = "Ordered languages advertised by Firefox-based browsers to websites.";
    };
    languagePacks = lib.options.mkOption {
      type = lib.types.listOf lib.types.nonEmptyStr;
      default = [ ];
      description = "Firefox language-pack identifiers to install for each enabled browser.";
    };
  }
  // lib.attrsets.genAttrs browserNames (name: {
    enable =
      lib.options.mkEnableOption "declarative ${name}"
      // lib.attrsets.optionalAttrs (name == "firefox") {
        default = true;
      };
    extraExtensions = lib.options.mkOption {
      type = lib.types.listOf extensionType;
      default = [ ];
      description = "Additional Tweezle extension declarations for ${name}";
    };
    extensionConfigFile = lib.options.mkOption {
      type = lib.types.nullOr lib.types.pathInStore;
      readOnly = true;
      description = "Tweezle extension configuration rendered for ${name}";
    };
    policiesFile = lib.options.mkOption {
      type = lib.types.nullOr lib.types.pathInStore;
      readOnly = true;
      description = "Browser policies rendered by Tweezle for ${name}";
    };
  });

  config.euvlok.home.firefox.extraExtensions = lib.lists.map addons.toTweezleExtension (
    lib.lists.filter lib.attrsets.isDerivation (
      lib.attrsets.attrValues (
        pkgs.callPackage ./extensions.nix {
          inherit (addons) buildFirefoxXpiAddon;
        }
      )
    )
  );

  config.programs =
    lib.attrsets.mapAttrs
      (
        name: package:
        lib.modules.mkIf
          (if name == "firefox" then cfg.enable && cfg.firefox.enable else cfg.${name}.enable)
          (
            {
              enable = true;
              profiles.default = default;
              inherit policies;
            }
            // lib.attrsets.optionalAttrs (name == "firefox" && pkgs.stdenv.hostPlatform.isDarwin) {
              darwinDefaultsId = "org.mozilla.nightlyunofficial";
              configPath = "Library/Application Support/Firefox";
            }
            // lib.attrsets.optionalAttrs (package != null) {
              package =
                if pkgs.stdenv.hostPlatform.isDarwin && name == "firefox" then
                  package
                else
                  package.override (old: {
                    extraPoliciesFiles = (old.extraPoliciesFiles or [ ]) ++ [ cfg.${name}.policiesFile ];
                  });
            }
          )
      )
      {
        inherit (pkgs) librewolf;
        firefox =
          if pkgs.stdenv.hostPlatform.isDarwin then
            unbrandedFirefox
          else
            pkgs.wrapFirefox unbrandedFirefox {
              pname = "firefox-unbranded";
              hasMozSystemDirPatch = false;
            };
        floorp = pkgs.unstable.floorp-bin;
        zen-browser = null;
      };
}
