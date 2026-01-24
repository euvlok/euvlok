{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib.strings) toSentenceCase;
in
{
  config = lib.mkIf config.catppuccin.enable {
    programs =
      let
        webFileIcons = inputs.firefox-addons-trivial.packages.${pkgs.stdenvNoCC.hostPlatform.system}.catppuccin-web-file-icons;
      in
      {
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
