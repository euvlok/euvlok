{
  pkgs,
  lib,
  ...
}:
let
  inherit (pkgs.stdenvNoCC) isDarwin;
in
{
  programs.nushell.shellAliases = {
    # Editors
    v = "hx";
    vi = "hx";
    vim = "hx";
    h = "hx";

    # Bring back da cat...
    cat = "open";
    open = "^open";

    # Programs
    htop = "btop";
    neofetch = "fastfetch";
  }
  // lib.optionalAttrs isDarwin { micfix = "sudo killall coreaudiod"; };
  programs.nushell.configFile.text = ''
    # Generic
    $env.EDITOR = "hx";
    $env.VISUAL = "hx";
    $env.config.show_banner = false;
    $env.config.buffer_editor = "hx";

    # Vi
    $env.config.edit_mode = "vi";
    $env.config.cursor_shape.vi_insert = "line"
    $env.config.cursor_shape.vi_normal = "block"
  '';
}
