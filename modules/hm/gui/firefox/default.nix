{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
let
  default = {
    extensions.packages = builtins.attrValues (
      pkgs.callPackage ./extensions.nix {
        buildFirefoxXpiAddon = (pkgs.callPackage ./firefox-addons.nix { }).buildFirefoxXpiAddon;
      }
    );

    extensions.force = true;
    search = {
      force = true;
      default = config.hm.firefox.defaultSearchEngine;
      privateDefault = config.hm.firefox.defaultSearchEngine;
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
  imports = [ inputs.zen-browser-trivial.homeModules.twilight ];

  options.hm.firefox = {
    enable = lib.mkEnableOption "Declarative Firefox-based Browsers";
    firefox.enable = lib.mkOption {
      default = true;
      description = "Enable Declerative Firefox";
    };
    floorp.enable = lib.mkEnableOption "Declarative Floorp";
    librewolf.enable = lib.mkEnableOption "Declarative LibreWolf";
    zen-browser.enable = lib.mkEnableOption "Declarative Zen Browser";
    defaultSearchEngine = lib.mkOption {
      default = "google";
      description = "Which Search Engine to set as Default";
      example = lib.literalExpression "Google";
      type = lib.types.enum [
        "ddg"
        "google"
        "kagi"
      ];
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.hm.firefox.enable {
      programs.firefox = {
        enable = true;
        package = pkgs.firefox;
        profiles.default = default;
        inherit policies;
      };
    })
    (lib.mkIf config.hm.firefox.floorp.enable {
      programs.floorp = {
        enable = true;
        package = pkgs.unstable.floorp-bin;
        profiles.default = default;
        inherit policies;
      };
    })
    (lib.mkIf config.hm.firefox.librewolf.enable {
      programs.librewolf = {
        enable = true;
        package = pkgs.librewolf;
        profiles.default = default;
        inherit policies;
      };
    })
    (lib.mkIf config.hm.firefox.zen-browser.enable {
      programs.zen-browser = {
        enable = true;
        profiles.default = default;
        inherit policies;
      };
    })
  ];
}
