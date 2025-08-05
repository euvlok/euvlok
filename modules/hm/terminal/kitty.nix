{
  lib,
  osConfig,
  config,
  ...
}:
{
  options.hm.kitty.enable = lib.mkEnableOption "Kitty";

  config = lib.mkIf config.hm.kitty.enable {
    programs.kitty = {
      enable = true;
      keybindings = {
        "kitty_mod" = if osConfig.nixpkgs.hostPlatform.isDarwin then "cmd" else "ctrl";
        "kitty_mod+shift+c" = "copy_to_clipboard";
        "kitty_mod+shift+v" = "paste_from_clipboard";
        "kitty_mod+t" = "new_window";
        "kitty_mod+shift+backspace" = "close_window";
      };
      darwinLaunchOptions = [
        "--single-instance"
        "--directory=/tmp/my-dir"
      ];
      settings = {
        scrollback_lines = 10000000;
        repaint_delay = 10;
        tab_bar_style = "powerline";
        notify_on_cmd_finish = "unfocused 5.0";
      }
      // lib.optionalAttrs osConfig.nixpkgs.hostPlatform.isDarwin {
        macos_option_as_alt = "yes";
        macos_quit_when_last_window_closed = "yes";
      };
    };
  };
}
