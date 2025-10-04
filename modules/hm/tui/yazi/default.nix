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
            rev = "d1c8baab86100afb708694d22b13901b9f9baf00";
            hash = "sha256-52Zn6OSSsuNNAeqqZidjOvfCSB7qPqUeizYq/gO+UbE=";
          };
        in
        {
          diff = "${pluginsRepo}/diff.yazi";
          full-border = "${pluginsRepo}/full-border.yazi";
          hide-preview = "${pluginsRepo}/hide-preview.yazi";
          max-preview = "${pluginsRepo}/max-preview.yazi";
          smart-enter = "${pluginsRepo}/smart-enter.yazi";
          system-clipboard = pkgs.applyPatches {
            src = pkgs.fetchFromGitHub {
              owner = "orhnk";
              repo = "system-clipboard.yazi";
              rev = "4f6942dd5f0e143586ab347d82dfd6c1f7f9c894";
              hash = "sha256-M7zKUlLcQA3ihpCAZyOkAy/SzLu31eqHGLkCSQPX1dY=";
            };
            patches = [
              (pkgs.writeText "system-clipboard-fix.patch" ''
                diff --git a/main.lua b/main.lua
                index 0e77f6a7bd..666604668d 100644
                --- a/main.lua
                +++ b/main.lua
                @@ -13,7 +13,7 @@
                 
                 return {
                 	entry = function()
                -		ya.manager_emit("escape", { visual = true })
                +		ya.mgr_emit("escape", { visual = true })
                 
                 		local urls = selected_or_hovered()
              '')
            ];
          };
        }
        // lib.optionalAttrs config.programs.git.enable { git = "${pluginsRepo}/git.yazi"; }
        // lib.optionalAttrs config.programs.starship.enable {
          starship = pkgs.fetchFromGitHub {
            owner = "Rolv-Apneseth";
            repo = "starship.yazi";
            rev = "6a0f3f788971b155cbc7cec47f6f11aebbc148c9";
            hash = "sha256-q1G0Y4JAuAv8+zckImzbRvozVn489qiYVGFQbdCxC98=";
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
