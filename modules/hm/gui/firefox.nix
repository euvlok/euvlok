{
  inputs,
  pkgs,
  lib,
  config,
  osConfig,
  ...
}:
let
  default = {
    extensions.packages =
      builtins.attrValues {
        inherit (pkgs.nur.repos.rycee.firefox-addons)
          clearurls
          firemonkey
          return-youtube-dislikes
          sponsorblock
          ublock-origin
          ;
      }
      ++ lib.optionals config.catppuccin.enable [
        pkgs.nur.repos.rycee.firefox-addons.catppuccin-web-file-icons
      ]
      ++ (lib.optionals (supportGnome) [ pkgs.nur.repos.rycee.firefox-addons.gnome-shell-integration ])
      ++ (lib.optionals (supportPlasma) [ pkgs.nur.repos.rycee.firefox-addons.plasma-integration ]);
    search = {
      force = true;
      default = config.hm.firefox.defaultSearchEngine;
      privateDefault = config.hm.firefox.defaultSearchEngine;
      order = [
        "GitHub"
        "Google"
        "Kagi"
        "Nix Packages"
        "YouTube"
      ];
      engines = {
        "DuckDuckGo" = {
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
          iconUpdateURL = "https://duckduckgo.com/favicon.ico";
          updateInterval = 24 * 60 * 60 * 1000;
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
          iconUpdateURL = "https://github.com/favicon.ico";
          updateInterval = 24 * 60 * 60 * 1000;
          definedAliases = [ "@gh" ];
        };
        "Google".metaData.alias = "@g"; # builtin engines only support specifying one additional alias
        "Kagi" = {
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
          iconUpdateURL = "https://assets.kagi.com/v2/apple-touch-icon.png";
          updateInterval = 24 * 60 * 60 * 1000;
          definedAliases = [ "@kagi" ];
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
        "YouTube" = {
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
          iconUpdateURL = "https://youtube.com/favicon.ico";
          updateInterval = 24 * 60 * 60 * 1000;
          definedAliases = [ "@yt" ];
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
      };
    };
    isDefault = true;
    settings =
      {
        "browser.urlbar.suggest.calculator" = true;
        "browser.urlbar.update2.engineAliasRefresh" = true;
      }
      // lib.optionalAttrs (!isLinux) {
        "widget.use-xdg-desktop-portal.file-picker" = 1;
      }
      // (lib.optionalAttrs (isLinux && (osConfig.nixos.nvidia.enable or osConfig.nixos.amd.enable)) {
        "media.ffmpeg.vaapi.enabled" = true;
        "media.gpu-process.enabled" = true;
      });
  };
  policies = {
    DisableTelemetry = true;
    # OfferToSaveLogins = false;
    # OfferToSaveLoginsDefault = false;
    # asswordManagerEnabled = false;
    NoDefaultBookmarks = true;
    # DisableFirefoxAccounts = true;
    DisableFeedbackCommands = true;
    DisableFirefoxStudies = true;
    DisableMasterPasswordCreation = true;
    DisablePocket = true;
    DisableSetDesktopBackground = true;
  };
  nativeMessagingHosts = lib.optionals supportGnome (
    builtins.attrValues {
      inherit (pkgs) gnome-browser-connector;
    }
  );
  isLinux = osConfig.nixpkgs.hostPlatform.isLinux;
  supportGnome = isLinux && osConfig.services.xserver.desktopManager.gnome.enable;
  supportPlasma = isLinux && osConfig.services.desktopManager.plasma6.enable;
in
{
  options.hm.firefox = {
    enable = lib.mkEnableOption "Declarative Firefox";
    defaultSearchEngine = lib.mkOption {
      default = "Google";
      description = "Which Search Engine to set as Default";
      example = lib.literalExpression "Google";
      type = lib.types.enum [
        "DuckDuckGo"
        "Google"
        "Kagi"
      ];
    };
  };

  config = lib.mkIf config.hm.firefox.enable {
    programs = {
      firefox = {
        enable = true;
        package = inputs.nixpkgs-unstable.legacyPackages.${osConfig.nixpkgs.hostPlatform.system}.firefox;
        profiles.default = default;
        inherit policies nativeMessagingHosts;
      };
      floorp = {
        enable = true;
        package = inputs.nixpkgs-unstable.legacyPackages.${osConfig.nixpkgs.hostPlatform.system}.floorp;
        profiles.default = default;
        inherit policies nativeMessagingHosts;
      };
    };
  };
}
