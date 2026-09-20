{ euvlokInputs }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  default = {
    extensions.packages = lib.lists.filter lib.attrsets.isDerivation (
      lib.attrsets.attrValues (
        pkgs.callPackage ./extensions.nix {
          inherit ((pkgs.callPackage ../../../../lib/firefox-addons.nix { })) buildFirefoxXpiAddon;
        }
      )
    );

    extensions.force = true;
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
  imports = [ euvlokInputs.zen-browser.homeModules.twilight ];

  options.euvlok.home.firefox = {
    enable = lib.options.mkEnableOption "declarative Firefox-based browsers";
    firefox.enable = lib.options.mkEnableOption "declarative Firefox" // {
      default = true;
    };
    floorp.enable = lib.options.mkEnableOption "declarative Floorp";
    librewolf.enable = lib.options.mkEnableOption "declarative LibreWolf";
    zen-browser.enable = lib.options.mkEnableOption "declarative Zen Browser";
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
  };

  config = lib.modules.mkMerge [
    (lib.modules.mkIf config.euvlok.home.firefox.enable {
      programs.firefox = {
        enable = true;
        package = pkgs.firefox;
        profiles.default = default;
        inherit (config.euvlok.home.firefox) languagePacks;
        inherit policies;
      };
    })
    (lib.modules.mkIf config.euvlok.home.firefox.floorp.enable {
      programs.floorp = {
        enable = true;
        package = pkgs.unstable.floorp-bin;
        profiles.default = default;
        inherit (config.euvlok.home.firefox) languagePacks;
        inherit policies;
      };
    })
    (lib.modules.mkIf config.euvlok.home.firefox.librewolf.enable {
      programs.librewolf = {
        enable = true;
        package = pkgs.librewolf;
        profiles.default = default;
        inherit (config.euvlok.home.firefox) languagePacks;
        inherit policies;
      };
    })
    (lib.modules.mkIf config.euvlok.home.firefox.zen-browser.enable {
      programs.zen-browser = {
        enable = true;
        profiles.default = default;
        inherit (config.euvlok.home.firefox) languagePacks;
        inherit policies;
      };
    })
  ];
}
