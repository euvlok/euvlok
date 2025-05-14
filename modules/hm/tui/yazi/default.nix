{
  inputs,
  pkgs,
  lib,
  config,
  osConfig,
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
      package = inputs.yazi-source.packages.${osConfig.nixpkgs.hostPlatform.system}.default;
      plugins =
        let
          pluginsRepo = pkgs.fetchFromGitHub {
            owner = "yazi-rs";
            repo = "plugins";
            rev = "55bf6996ada3df4cbad331ce3be0c1090769fc7c";
            hash = "sha256-v/C+ZBrF1ghDt1SXpZcDELmHMVAqfr44iWxzUWynyRk=";
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
            rev = "efb8f03e632adcdc6677fd5f471c74f4c71fdf9a";
            hash = "sha256-zOQQvbkXq71t2E4x45oM4MzVRlZ4hhe6RkvgcP8tdYE=";
          };
        }
        // lib.optionalAttrs config.programs.git.enable { git = "${pluginsRepo}/git.yazi"; }
        // lib.optionalAttrs config.programs.starship.enable {
          starship = pkgs.fetchFromGitHub {
            owner = "Rolv-Apneseth";
            repo = "starship.yazi";
            rev = "c0707544f1d526f704dab2da15f379ec90d613c2";
            hash = "sha256-H8j+9jcdcpPFXVO/XQZL3zq1l5f/WiOm4YUxAMduSRs=";
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
