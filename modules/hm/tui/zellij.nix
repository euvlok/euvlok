{
  lib,
  config,
  pkgs,
  osConfig,
  euvlok,
  ...
}:
let
  inherit (osConfig.nixpkgs.hostPlatform) isDarwin;
  inherit (euvlok)
    mkBind
    mkShiftBind
    mkSimpleBind
    mkDirectionalNav
    mkModeSwitch
    mkQuit
    ;

  modKey = if isDarwin then "Super" else "Ctrl";
in
{
  options.hm.zellij.enable = lib.mkEnableOption "Zellij";

  config = lib.mkIf config.hm.zellij.enable {
    programs.zellij.enable = true;
    programs.zellij.settings = {
      default_shell = "${lib.getExe pkgs.bash}";
      copy_command = if isDarwin then "pbcopy" else "wl-copy";
      copy_clipboard = "system";
      copy_on_select = false;
      mirror_session = true;
      show_startup_tips = false;

      keybinds = {
        normal = lib.mkMerge [
          # Basic bindings
          (mkBind { inherit modKey; } "t" { NewTab = { }; }) # New tab
          (mkBind { inherit modKey; } "k" { Clear = { }; }) # Clear pane text
          (mkBind { inherit modKey; } "c" { Copy = { }; })

          # Basic mode switches
          (mkModeSwitch modKey "g" "Locked")
          (mkQuit modKey "q")

          # Directional navigation
          (mkDirectionalNav modKey)

          # Tab switching (1-9)
          (lib.mkMerge (map (n: mkBind { inherit modKey; } (toString n) { GoToTab = n; }) (lib.range 1 9)))
        ];

        locked = (mkModeSwitch modKey "g" "Normal");
      };
    };
  };
}
