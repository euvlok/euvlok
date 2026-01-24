{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
{
  imports = [
    ./keybindings.nix
    ./settings.nix
  ];

  options.hm.yazi.enable = lib.mkEnableOption "Yazi";

  config = lib.mkIf config.hm.yazi.enable {
    home.packages = builtins.attrValues { inherit (pkgs) mediainfo exiftool clipboard-jh; };
    programs.yazi = {
      enable = true;
      package = pkgs.unstable.yazi;
      plugins =
        let
          pluginsRepo = pkgs.fetchFromGitHub {
            owner = "yazi-rs";
            repo = "plugins";
            rev = "8f1d9711bcd0e48af1fcb4153c16d24da76e732d";
            hash = "sha256-7vsqHvdNimH/YVWegfAo7DfJ+InDr3a1aNU0f+gjcdw=";
          };
        in
        {
          diff = "${pluginsRepo}/diff.yazi";
          full-border = "${pluginsRepo}/full-border.yazi";
          hide-preview = "${pluginsRepo}/hide-preview.yazi";
          max-preview = "${pluginsRepo}/max-preview.yazi";
          smart-enter = "${pluginsRepo}/smart-enter.yazi";
          smart-paste = "${pluginsRepo}/smart-paste.yazi";
          system-clipboard = pkgs.fetchFromGitHub {
            owner = "orhnk";
            repo = "system-clipboard.yazi";
            rev = "888026c6d5988bd9dc5be51f7f96787bb8cadc4b";
            hash = "sha256-8YtYYxNDfQBTyMxn6Q7/BCiTiscpiZFXRuX0riMlRWQ=";
          };
        }
        // lib.optionalAttrs config.programs.git.enable { git = "${pluginsRepo}/git.yazi"; }
        // lib.optionalAttrs config.programs.starship.enable {
          starship = pkgs.fetchFromGitHub {
            owner = "Rolv-Apneseth";
            repo = "starship.yazi";
            rev = "a63550b2f91f0553cc545fd8081a03810bc41bc0";
            hash = "sha256-PYeR6fiWDbUMpJbTFSkM57FzmCbsB4W4IXXe25wLncg=";
          };
        };
      initLua = builtins.concatStringsSep "\n" (
        [ "require('full-border'):setup()" ]
        ++ lib.optional config.programs.git.enable ''require("git"):setup()''
        ++ lib.optional config.programs.starship.enable ''require("starship"):setup()''
      );
    };
  };
}
