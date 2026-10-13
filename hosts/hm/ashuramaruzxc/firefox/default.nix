{
  pkgs,
  lib,
  ...
}:
let
  search = {
    force = true;
    order = lib.modules.mkForce [
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
    "extensions.webextensions.restrictedDomains" =
      lib.strings.concatStringsSep "," restrictedDomainsList;
    "dom.webgpu.enabled" = true;
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
    "oauth.accounts.firefox.com"
    "private.tenjin.com"
    "profile.accounts.firefox.com"
    "public.tenjin.com"
    "support.mozilla.org"
    "sync.services.mozilla.com"
  ];

  inherit (pkgs.callPackage ../../../../lib/firefox-addons.nix { })
    buildFirefoxXpiAddon
    toTweezleExtension
    ;
  sharedExtensions = pkgs.callPackage ../../../../modules/hm/gui/firefox/extensions.nix {
    inherit buildFirefoxXpiAddon;
  };
  defaultExtensionsList = lib.lists.map toTweezleExtension (
    lib.lists.filter lib.attrsets.isDerivation (
      lib.attrsets.attrValues (
        (pkgs.callPackage ./extensions.nix { inherit buildFirefoxXpiAddon; })
        // (import ../../../../slop.nix).firefoxExtensions { inherit buildFirefoxXpiAddon lib; }
        // {
          inherit (sharedExtensions) "magnolia@12.34";
        }
      )
    )
  );
in
{

  euvlok.home.firefox = {
    floorp.extraExtensions = defaultExtensionsList;
    zen-browser.extraExtensions = defaultExtensionsList;
    acceptedLanguages = [
      "en-US"
      "en"
      "pl"
      "uk"
      "ru"
      "ja"
      "fr"
    ];
    languagePacks = [
      "en-US"
      "en-GB"
      "en-CA"
      "pl"
      "uk"
      "ru"
      "ja"
      "fr"
    ];
  };

  programs.floorp = {
    profiles.default = {
      inherit search settings;
    };
    profiles.backup = {
      id = 1;
      inherit search settings;
    };
    nativeMessagingHosts = lib.modules.mkIf pkgs.stdenvNoCC.hostPlatform.isLinux (
      lib.attrsets.attrValues { inherit (pkgs) keepassxc; }
    );
  };
  programs.zen-browser = {
    profiles.default = {
      settings = zenSettings;
      inherit search;
    };
    profiles.backup = {
      id = 1;
      settings = zenSettings;
      inherit search;
    };
    nativeMessagingHosts = lib.modules.mkIf (
      pkgs.stdenvNoCC.hostPlatform.isLinux && pkgs.stdenvNoCC.hostPlatform.isx86_64
    ) (lib.attrsets.attrValues { inherit (pkgs.unstable) keepassxc; });
  };
}
