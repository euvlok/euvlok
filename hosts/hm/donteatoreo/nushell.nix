{
  pkgs,
  lib,
  osConfig,
  ...
}:
let
  inherit (osConfig.nixpkgs.hostPlatform) isDarwin;
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

    # Nix
    check =
      if isDarwin then
        "darwin-rebuild check --flake $env.NIX_CONFIG_HOME"
      else
        "nix flake check $env.NIX_CONFIG_HOME";
    rebuild =
      if isDarwin then
        "darwin-rebuild switch --flake $env.NIX_CONFIG_HOME"
      else
        "nixos-rebuild switch --use-remote-sudo --flake $env.NIX_CONFIG_HOME";
  } // lib.optionalAttrs isDarwin { micfix = "sudo killall coreaudiod"; };
  programs.nushell.configFile.text =
    ''
      # Generic
      $env.EDITOR = "hx";
      $env.VISUAL = "hx";
      $env.config.show_banner = false;
      $env.config.buffer_editor = "hx";

      # Vi
      $env.config.edit_mode = "vi";
      $env.config.cursor_shape.vi_insert = "line"
      $env.config.cursor_shape.vi_normal = "block"
    ''
    + lib.optionalString (lib.any (pkg: pkg == pkgs.github-copilot-cli) (
      osConfig.environment.systemPackages
    )) "source ${../../../modules/scripts/github-copilot-cli.nu}";
}
