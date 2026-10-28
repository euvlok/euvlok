{
  config,
  options,
  lib,
  pkgs,
  ...
}:
let
  toSentenceCase = lib.strings.toSentenceCase;
in
{

  config = lib.attrsets.optionalAttrs (options.programs ? zen-browser) (
    lib.modules.mkIf (config.catppuccin.enable && config.programs.zen-browser.enable) {
      programs.zen-browser.profiles.default = {
        settings."toolkit.legacyUserProfileCustomizations.stylesheets" = true;
      };

      home.file =
        let
          catppuccinZen = pkgs.fetchFromGitHub {
            owner = "catppuccin";
            repo = "zen-browser";
            rev = "c855685442c6040c4dda9c8d3ddc7b708de1cbaa";
            sha256 = "sha256-5A57Lyctq497SSph7B+ucuEyF1gGVTsuI3zuBItGfg4=";
          };
          inherit (config.programs.zen-browser) profilesPath;
          profileDir = "${profilesPath}/${config.programs.zen-browser.profiles.default.path}";
          themeDir = "${catppuccinZen}/themes/${toSentenceCase config.catppuccin.flavor}/${toSentenceCase config.catppuccin.accent}";
        in
        {
          "${profileDir}/chrome/userChrome.css".source = "${themeDir}/userChrome.css";
          "${profileDir}/chrome/userContent.css".source = "${themeDir}/userContent.css";
          "${profileDir}/chrome/zen-logo.svg".source = "${themeDir}/zen-logo.svg";
        };
    }
  );
}
