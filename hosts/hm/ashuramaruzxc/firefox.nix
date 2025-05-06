{
  inputs,
  pkgs,
  lib,
  osConfig,
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
        icon = "https://steamdb.info/static/logos/512px.png";
        updateInterval = 7 * 24 * 60 * 60 * 1000;
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
        icon = "https://www.protondb.com/sites/protondb/images/favicon.ico";
        updateInterval = 7 * 24 * 60 * 60 * 1000;
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
        icon = "https://www.youtube.com/s/desktop/5d5de6d9/img/favicon.ico";
        updateInterval = 7 * 24 * 60 * 60 * 1000;
        definedAliases = [
          "@ytm"
          "@ym"
        ];
      };
    };
  };

  bypass-paywalls-clean =
    let
      version = "4.1.0.0";
    in
    inputs.firefox-addons.lib.${osConfig.nixpkgs.hostPlatform.system}.buildFirefoxXpiAddon {
      pname = "bypass-paywalls-clean";
      inherit version;
      addonId = "magnolia@12.34";
      url = "https://gitflic.ru/project/magnolia1234/bpc_uploads/blob/raw?file=bypass_paywalls_clean-${version}.xpi&inline=false&commit=b5a2bf54181be5d93476d83b42ec32044b3131e1";
      name = "bypass-paywall-clean-${version}";
      sha256 = "sha256-VIcHif8gA+11oL5AsADaHA6qfWT8+S0A8msaYE2ivns=";
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
    "metrics.tenjin-dk.com"
    "oauth.accounts.firefox.com"
    "private.tenjin.com"
    "profile.accounts.firefox.com"
    "public.tenjin.com"
    "support.mozilla.org"
    "sync.services.mozilla.com"
  ];
in
{
  programs.floorp = {
    enable = true;
    profiles.default = {
      settings = {
        "extensions.webextensions.restrictedDomains" = builtins.concatStringsSep "," restrictedDomainsList;
      };
      extensions.packages = builtins.attrValues {
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
      inherit search;
    };
    #! keep an eye on
    #! https://github.com/NixOS/nixpkgs/pull/374068
    #! https://github.com/NixOS/nixpkgs/issues/347350
    nativeMessagingHosts = (
      lib.optionals (osConfig.nixpkgs.hostPlatform.isLinux) builtins.attrValues {
        inherit (pkgs) firefoxpwa;
      }
    );
    languagePacks = [
      "en-CA"
      "en-GB"
      "en-US"
      "ja"
    ];
  };
  home.packages = (
    lib.optionals (osConfig.nixpkgs.hostPlatform.isLinux) builtins.attrValues {
      inherit (pkgs) firefoxpwa;
    }
  );
}
