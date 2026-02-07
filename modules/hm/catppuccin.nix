{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib.strings) toSentenceCase;

  buildFirefoxXpiAddon = (pkgs.callPackage ./gui/firefox/firefox-addons.nix { }).buildFirefoxXpiAddon;

  webFileIcons = buildFirefoxXpiAddon {
    pname = "catppuccin-web-file-icons";
    version = "1.6.1";
    addonId = "{bbb880ce-43c9-47ae-b746-c3e0096c5b76}";
    url = "https://addons.mozilla.org/firefox/downloads/file/4647055/catppuccin_web_file_icons-1.6.1.xpi";
    sha256 = "sha256-a1ee2312bd2cb1306a38dec4b50edc55a43979d818733264dee955c6c04a7676";
    meta = with lib; {
      homepage = "https://github.com/catppuccin/web-file-explorer-icons";
      description = "Soothing pastel icons for file explorers on the web!";
      license = licenses.mit;
      mozPermissions = [
        "storage"
        "contextMenus"
        "activeTab"
        "*://bitbucket.org/*"
        "*://codeberg.org/*"
        "*://gitea.com/*"
        "*://github.com/*"
        "*://gitlab.com/*"
        "*://tangled.org/*"
      ];
      platforms = platforms.all;
    };
  };
in
{
  config = lib.mkIf config.catppuccin.enable {
    programs = {
      firefox.profiles.default.extensions.packages = [ webFileIcons ];
      floorp.profiles.default.extensions.packages = [ webFileIcons ];
      librewolf.profiles.default.extensions.packages = [ webFileIcons ];
      zen-browser.profiles.default = {
        extensions.packages = [ webFileIcons ];
        settings = {
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        };
      };
    };
    home.file =
      let
        catppuccinZen = pkgs.fetchFromGitHub {
          owner = "catppuccin";
          repo = "zen-browser";
          rev = "main";
          sha256 = "sha256-5A57Lyctq497SSph7B+ucuEyF1gGVTsuI3zuBItGfg4=";
        };
        inherit (config.programs.zen-browser) profilesPath;
        themeDir = "${catppuccinZen}/themes/${toSentenceCase config.catppuccin.flavor}/${toSentenceCase config.catppuccin.accent}";
      in
      {
        "${profilesPath}/default/chrome/userChrome.css".source = "${themeDir}/userChrome.css";
        "${profilesPath}/default/chrome/userContent.css".source = "${themeDir}/userContent.css";
        "${profilesPath}/default/chrome/zen-logo.svg".source = "${themeDir}/zen-logo.svg";
      };
  };
}
