{
  inputs,
  pkgs,
  lib,
  config,
  osConfig,
  ...
}:
let
  inherit (lib.strings) toSentenceCase;
  catppuccinZen = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "zen-browser";
    rev = "main";
    sha256 = "sha256-5A57Lyctq497SSph7B+ucuEyF1gGVTsuI3zuBItGfg4=";
  };
  themeDir = "${catppuccinZen}/themes/${toSentenceCase config.catppuccin.flavor}/${toSentenceCase config.catppuccin.accent}";
  profilesPath = config.programs.zen-browser.profilesPath;

  default = {
    extensions.packages =
      builtins.attrValues {
        inherit (pkgs.nur.repos.rycee.firefox-addons)
          clearurls
          firemonkey
          refined-github
          sponsorblock
          ublock-origin
          ;
      }
      ++ lib.optionals config.catppuccin.enable [
        pkgs.nur.repos.rycee.firefox-addons.catppuccin-web-file-icons
      ]
      ++ (lib.optionals (supportGnome) [ pkgs.nur.repos.rycee.firefox-addons.gnome-shell-integration ])
      ++ (lib.optionals (supportPlasma) [ pkgs.nur.repos.rycee.firefox-addons.plasma-integration ]);
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
    }
    // lib.optionalAttrs (isLinux && osConfig.xdg.portal.xdgOpenUsePortal == true) {
      "widget.use-xdg-desktop-portal.file-picker" = 1;
    }
    // (lib.optionalAttrs (isLinux && (osConfig.nixos.nvidia.enable or osConfig.nixos.amd.enable)) {
      "media.ffmpeg.vaapi.enabled" = true;
      "media.gpu-process.enabled" = true;
    });
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
  nativeMessagingHosts = lib.mkIf isLinux (
    builtins.attrValues (
      lib.optionalAttrs supportGnome { inherit (pkgs) gnome-browser-connector; }
      // lib.optionalAttrs supportPlasma { inherit (pkgs.kdePackages) plasma-integration; }
    )
  );
  isLinux = osConfig.nixpkgs.hostPlatform.isLinux;
  supportGnome = isLinux && osConfig.services.xserver.desktopManager.gnome.enable;
  supportPlasma = isLinux && osConfig.services.desktopManager.plasma6.enable;
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
        inherit policies nativeMessagingHosts;
      };
    })
    (lib.mkIf config.hm.firefox.floorp.enable {
      programs.floorp = {
        enable = true;
        package = pkgs.floorp;
        profiles.default = default;
        inherit policies nativeMessagingHosts;
      };
    })
    (lib.mkIf config.hm.firefox.librewolf.enable {
      programs.librewolf = {
        enable = true;
        package = pkgs.librewolf;
        profiles.default = default;
        inherit policies nativeMessagingHosts;
      };
    })
    (lib.mkIf config.hm.firefox.zen-browser.enable {
      programs.zen-browser = {
        enable = true;
        profiles.default = default;
        inherit policies nativeMessagingHosts;
      };
    })
    (lib.mkIf (config.catppuccin.enable && config.hm.firefox.zen-browser.enable) {
      programs.zen-browser.profiles.default.settings = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
      };
      home.file = {
        "${profilesPath}/default/chrome/userChrome.css".source = "${themeDir}/userChrome.css";
        "${profilesPath}/default/chrome/userContent.css".source = "${themeDir}/userContent.css";
        "${profilesPath}/default/chrome/zen-logo.svg".source = "${themeDir}/zen-logo.svg";
      };
    })
    {
      home.packages = (lib.optionals (supportGnome) [ pkgs.gnome-browser-connector ]);
      # ++ (lib.optionals (supportPlasma) [ pkgs.kdePackages.plasma-integration ]);
    }
  ];
}
