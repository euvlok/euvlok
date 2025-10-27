{
  inputs,
  pkgs,
  pkgsUnstable,
  lib,
  ...
}:
let
  search = {
    force = true;
    order = lib.mkForce [
      "kagi"
      "google"
      "ddg"
      "NixOS Wiki"
      "Nix Options"
      "Nix Packages"
      "Home Manager"
      "GitHub"
      "SteamDB"
      "ProtonDB"
      "youtube"
      "YoutubeMusic"
    ];
    engines = {
      "bing".metaData.hidden = true;
      "you".metaData.hidden = true;
      "you.com".metaData.hidden = true;
      "SteamDB" = {
        urls = [
          {
            template = "https://steamdb.info/search";
            params = [
              {
                name = "a";
                value = "app";
              }
              {
                name = "q";
                value = "{searchTerms}";
              }
            ];
          }
        ];
        iconMapObj."16" = "https://steamdb.info/favicon.ico";
        definedAliases = [ "@steamdb" ];
      };
      "ProtonDB" = {
        urls = [
          {
            template = "https://www.protondb.com/search";
            params = [
              {
                name = "q";
                value = "{searchTerms}";
              }
            ];
          }
        ];
        iconMapObj."16" = "https://www.protondb.com/sites/protondb/images/favicon.ico";
        definedAliases = [ "@protondb" ];
      };
      "YoutubeMusic" = {
        urls = [
          {
            template = "https://music.youtube.com/search";
            params = [
              {
                name = "q";
                value = "{searchTerms}";
              }
            ];
          }
        ];
        iconMapObj."16" = "https://music.youtube.com/favicon.ico";
        definedAliases = [ "@ytm" ];
      };
    };
  };
  settings = {
    "extensions.webextensions.restrictedDomains" = builtins.concatStringsSep "," restrictedDomainsList;
    "gfx.webrender.all" = true;
    "media.av1.enabled" = true;
  };
  zenSettings = settings // {
    "zen.urlbar.replace-newtab" = false;
  };
  bypass-paywalls-clean =
    let
      version = "latest";
    in
    inputs.firefox-addons-trivial.lib.${pkgs.system}.buildFirefoxXpiAddon {
      pname = "bypass-paywalls-clean";
      inherit version;
      addonId = "magnolia@12.34";
      url = "https://gitflic.ru/project/magnolia1234/bpc_uploads/blob/raw?file=bypass_paywalls_clean-${version}.xpi";
      name = "bypass-paywall-clean-${version}";
      sha256 = "sha256-sFcIlR0wgmXiJovqw+10Mh+qaMl5heIvHntk6DeC3TU=";
      meta = {
        homepage = "https://twitter.com/Magnolia1234B";
        description = "Bypass Paywalls of (custom) news sites";
        license = lib.licenses.mit;
        platforms = lib.platforms.all;
      };
    };

  restrictedDomainsList = [
    "accounts-static.cdn.mozilla.net"
    "accounts.firefox.com"
    "addons.cdn.mozilla.net"
    "addons.mozilla.org"
    "api.accounts.firefox.com"
    "beta.foldingathome.org"
    "cloud.tenjin-dk.com"
    "content.cdn.mozilla.net"
    "discovery.addons.mozilla.org"
    "install.mozilla.org"
    "media.tenjin-dk.com"
    "media.tenjin.com"
    "metrics.tenjin-dk.com"
    "metrics.tenjin.com"
    "oauth.accounts.firefox.com"
    "private.tenjin.com"
    "profile.accounts.firefox.com"
    "public.tenjin.com"
    "support.mozilla.org"
    "sync.services.mozilla.com"
  ];
  defaultExtensionsList = builtins.attrValues {
    inherit (pkgs.nur.repos.rycee.firefox-addons)
      # necessity
      darkreader
      facebook-container
      mullvad
      multi-account-containers
      user-agent-string-switcher
      web-archives

      # devtools
      angular-devtools
      react-devtools
      reduxdevtools
      vue-js-devtools

      youtube-no-translation
      bitwarden
      firefox-color
      floccus
      foxyproxy-standard
      old-reddit-redirect
      reddit-enhancement-suite
      search-by-image
      steam-database
      stylus
      tabliss
      translate-web-pages

      # Dictionaries
      ukrainian-dictionary
      french-dictionary
      dictionary-german
      polish-dictionary
      bulgarian-dictionary
      ;
    inherit bypass-paywalls-clean;
  };
in
{
  #! bitwarden is still broken

  config = lib.mkIf pkgs.stdenvNoCC.isDarwin {
    programs.floorp = {
      enable = true;
      profiles.default = {
        extensions.packages = defaultExtensionsList;
        extensions.force = true;
        inherit search settings;
      };
      profiles.backup = {
        id = 1;
        extensions.packages = defaultExtensionsList;
        extensions.force = true;
        inherit search settings;
      };
      nativeMessagingHosts = lib.mkIf pkgs.stdenvNoCC.isLinux (
        builtins.attrValues { inherit (pkgs) firefoxpwa; }
      );
      languagePacks = [
        "en-CA"
        "en-GB"
        "en-US"
        "ja"
      ];
    };
    programs.zen-browser = {
      enable = true;
      profiles.default = {
        settings = zenSettings;
        extensions.packages = defaultExtensionsList;
        extensions.force = true;
        inherit search;
      };
      profiles.backup = {
        id = 1;
        settings = zenSettings;
        extensions.packages = defaultExtensionsList;
        extensions.force = true;
      };
      nativeMessagingHosts = lib.mkIf pkgs.stdenvNoCC.isLinux (
        builtins.attrValues { inherit (pkgsUnstable) firefoxpwa; }
      );
      languagePacks = [
        "en-CA"
        "en-GB"
        "en-US"
        "ja"
      ];
    };
    home.packages = lib.mkIf pkgs.stdenvNoCC.isLinux (
      builtins.attrValues {
        inherit (pkgs) firefoxpwa;
      }
    );
  };
}
