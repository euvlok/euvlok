{
  inputs,
  pkgs,
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
    "metrics.tenjin.com"
    "metrics.tenjin.com"
    "oauth.accounts.firefox.com"
    "private.tenjin.com"
    "profile.accounts.firefox.com"
    "public.tenjin.com"
    "support.mozilla.org"
    "sync.services.mozilla.com"
  ];

  defaultExtensionsList = builtins.filter (lib.isDerivation) (
    builtins.attrValues (
      pkgs.callPackage ./extensions.nix {
        buildFirefoxXpiAddon =
          (pkgs.callPackage ../../../../modules/hm/gui/firefox/firefox-addons.nix { }).buildFirefoxXpiAddon;
      }
    )
  );
in
{
  programs.floorp = {
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
      builtins.attrValues { inherit (pkgs) keepassxc; }
    );
    languagePacks = [
      "en-CA"
      "en-GB"
      "en-US"
      "ja"
    ];
  };
  programs.zen-browser = {
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
      inherit search;
    };
    nativeMessagingHosts = lib.mkIf (pkgs.stdenvNoCC.isLinux && pkgs.stdenvNoCC.isx86_64) (
      builtins.attrValues { inherit (pkgs.unstable) keepassxc; }
    );
    languagePacks = [
      "en-CA"
      "en-GB"
      "en-US"
      "ja"
    ];
  };
}
