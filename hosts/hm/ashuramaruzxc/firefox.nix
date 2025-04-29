{
  pkgs,
  lib,
  osConfig,
  config,
  inputs,
  ...
}:
let
  search = {
    force = true;
    order = lib.mkForce [
      "Kagi"
      "google"
      "ddg"
      "Home Manager"
      "Nix Options"
      "Nix Packages"
      "NixOS Wiki"
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
        icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
        definedAliases = [ "@nw" ];
      };
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
  old-twitter-layout =
    let
      pname = "old-twitter-layout-2024";
      version = "1.8.9.9";
      addonId = "4473235";
    in
    inputs.firefox-addons.lib.${osConfig.nixpkgs.hostPlatform.system}.buildFirefoxXpiAddon {
      inherit pname version addonId;
      url = "https://addons.mozilla.org/firefox/downloads/file/${addonId}/${pname}-${version}.xpi";
      name = "${pname}";
      sha256 = "sha256-XxWcd5Ku2jpw2652/j2iJmUUrLzqJn6LOMEawlOKkGY=";
      meta = {
        homepage = "https://github.com/dimdenGD/OldTwitter";
        description = "Extension to return old Twitter layout from 2015 / 2018";
        # license = lib.licenses.unfree; # for some reason ?? ?? ? ? ? ??
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
          mullvad
          darkreader

          facebook-container

          user-agent-string-switcher
          web-archives

          # devtools
          angular-devtools
          react-devtools
          reduxdevtools
          vue-js-devtools

          # utils
          multi-account-containers

          stylus
          steam-database
          search-by-image
          foxyproxy-standard
          bitwarden
          firefox-translations
          floccus
          tabliss
          old-reddit-redirect
          reddit-enhancement-suite

          # Dictionaries
          ukrainian-dictionary
          french-dictionary
          dictionary-german
          polish-dictionary
          bulgarian-dictionary
          ;
        inherit bypass-paywalls-clean old-twitter-layout;
      };
      inherit search;
    };
    # nativeMessagingHosts = [
    #   pkgs.firefoxpwa
    #   pkgs.keepassxc
    # ];
  };
  # home.packages = [
  #   pkgs.firefoxpwa
  #   pkgs.keepassxc
  # ];
  programs.firefox.enable = lib.mkForce false;
}
