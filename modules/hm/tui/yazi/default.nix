{
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
    xdg.configFile = {
      "yazi/plugins/smart-paste.yazi/main.lua".text = ''
        --- @sync entry
        return {
          entry = function()
            local h = cx.active.current.hovered
            if h and h.cha.is_dir then
              ya.manager_emit("enter", {})
              ya.manager_emit("paste", {})
              ya.manager_emit("leave", {})
            else
              ya.manager_emit("paste", {})
            end
          end,
        }
      '';
    };
    home.packages = builtins.attrValues { inherit (pkgs) mediainfo exiftool clipboard-jh; };
    programs.yazi = {
      enable = true;
      plugins =
        let
          pluginsRepo = pkgs.fetchFromGitHub {
            owner = "yazi-rs";
            repo = "plugins";
            rev =
              if (lib.strings.versionOlder config.programs.yazi.package.version "25.3.2") then
                "a1738e8088366ba73b33da5f45010796fb33221e"
              else
                "b12a9ab085a8c2fe2b921e1547ee667b714185f9";
            hash =
              if (lib.strings.versionOlder config.programs.yazi.package.version "25.3.2") then
                "sha256-eiLkIWviGzG9R0XP1Cik3Bg0s6lgk3nibN6bZvo8e9o="
              else
                "sha256-LWN0riaUazQl3llTNNUMktG+7GLAHaG/IxNj1gFhDRE=";
          };
        in
        {
          diff = "${pluginsRepo}/diff.yazi";
          full-border = "${pluginsRepo}/full-border.yazi";
          hide-preview = "${pluginsRepo}/hide-preview.yazi";
          max-preview = "${pluginsRepo}/max-preview.yazi";
          smart-enter = "${pluginsRepo}/smart-enter.yazi";
          system-clipboard = pkgs.fetchFromGitHub {
            owner = "orhnk";
            repo = "system-clipboard.yazi";
            rev =
              if (lib.strings.versionOlder config.programs.yazi.package.version "25.3.2") then
                "efb8f03e632adcdc6677fd5f471c74f4c71fdf9a"
              else
                "efb8f03e632adcdc6677fd5f471c74f4c71fdf9a";
            hash =
              if (lib.strings.versionOlder config.programs.yazi.package.version "25.3.2") then
                "sha256-zOQQvbkXq71t2E4x45oM4MzVRlZ4hhe6RkvgcP8tdYE="
              else
                "sha256-zOQQvbkXq71t2E4x45oM4MzVRlZ4hhe6RkvgcP8tdYE=";
          };
        }
        // lib.optionalAttrs config.programs.git.enable { git = "${pluginsRepo}/git.yazi"; }
        // lib.optionalAttrs config.programs.starship.enable {
          starship = pkgs.fetchFromGitHub {
            owner = "Rolv-Apneseth";
            repo = "starship.yazi";
            rev =
              if (lib.strings.versionOlder config.programs.yazi.package.version "25.3.2") then
                "6c639b474aabb17f5fecce18a4c97bf90b016512"
              else
                "c0707544f1d526f704dab2da15f379ec90d613c2";
            hash =
              if (lib.strings.versionOlder config.programs.yazi.package.version "25.3.2") then
                "sha256-bhLUziCDnF4QDCyysRn7Az35RAy8ibZIVUzoPgyEO1A="
              else
                "sha256-H8j+9jcdcpPFXVO/XQZL3zq1l5f/WiOm4YUxAMduSRs=";
          };
        };
      initLua = builtins.concatStringsSep "\n" (
        [ ''require('full-border'):setup()'' ]
        ++ lib.optional config.programs.git.enable ''require("git"):setup()''
        ++ lib.optional config.programs.starship.enable ''require("starship"):setup()''
      );
    };
  };
}
